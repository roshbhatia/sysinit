local M = {}

-- -@class harness.OptionDef

local persist = require("harness.persist")
local STATE_FILE = persist.path("options")

-- -@type table<string, table<string, any>>  agent_name → { opt_name = value }
local state = {}
local loaded = false

local function load()
  if loaded then
    return
  end
  loaded = true
  state = persist.load(STATE_FILE) or {}
end

local function save()
  persist.save(STATE_FILE, state)
end

-- -@param agent_name string -@return harness.OptionDef[]|nil
function M.get_schema(agent_name)
  local ok, adapter = pcall(require, "harness.adapters." .. agent_name)
  if not ok then
    return nil
  end
  return adapter.options_schema
end

-- -@param agent_name string -@return table<string, any>
function M.get_selected(agent_name)
  load()
  if not state[agent_name] then
    state[agent_name] = {}
    local schema = M.get_schema(agent_name)
    if schema then
      for _, opt in ipairs(schema) do
        if opt.default ~= nil then
          state[agent_name][opt.name] = opt.default
        end
      end
    end
    save()
  end
  return state[agent_name]
end

-- -@param agent_name string
function M.set(agent_name, opt_name, value)
  local sel = M.get_selected(agent_name)
  sel[opt_name] = value
  save()
end

-- -@param agent_name string -@param opt_name string
function M.toggle(agent_name, opt_name)
  local sel = M.get_selected(agent_name)
  sel[opt_name] = not sel[opt_name]
  save()
end

-- -@param agent_name string
function M.reset(agent_name)
  load()
  state[agent_name] = nil
  save()
end

-- -@param agent_name string -@return string[]
function M.build_args(agent_name)
  local schema = M.get_schema(agent_name)
  if not schema then
    return {}
  end
  local sel = M.get_selected(agent_name)
  local args = {}
  for _, opt in ipairs(schema) do
    if opt.cli ~= false then
      local v = sel[opt.name]
      if opt.kind == "toggle" then
        if v then
          table.insert(args, opt.flag)
        end
      elseif opt.kind == "value" or opt.kind == "enum" then
        if v and v ~= "" then
          table.insert(args, opt.flag)
          table.insert(args, tostring(v))
        end
      elseif opt.kind == "opt_value" then
        if v == true then
          table.insert(args, opt.flag)
        elseif type(v) == "string" and v ~= "" then
          table.insert(args, opt.flag)
          table.insert(args, v)
        end
      elseif opt.kind == "list" then
        if type(v) == "string" and v ~= "" then
          for _, item in ipairs(vim.split(v, ",", { plain = true, trimempty = true })) do
            item = vim.trim(item)
            if item ~= "" then
              table.insert(args, opt.flag)
              table.insert(args, item)
            end
          end
        end
      end
    end
  end
  return args
end

-- -@param agent_name string -@return string
function M.summary(agent_name)
  local schema = M.get_schema(agent_name)
  if not schema then
    return ""
  end
  local sel = M.get_selected(agent_name)
  local parts = {}
  for _, opt in ipairs(schema) do
    local v = sel[opt.name]
    local display = opt.label or opt.flag
    if opt.kind == "toggle" then
      if v then
        table.insert(parts, display)
      end
    elseif opt.kind == "opt_value" then
      if v == true then
        table.insert(parts, display)
      elseif type(v) == "string" and v ~= "" then
        table.insert(parts, display .. "=" .. v)
      end
    elseif v and v ~= "" then
      table.insert(parts, display .. "=" .. tostring(v))
    end
  end
  return table.concat(parts, " ")
end

-- -@param agent_name string -@param on_close?
function M.configure(agent_name, on_close)
  local schema = M.get_schema(agent_name)
  if not schema or #schema == 0 then
    vim.notify("harness: " .. agent_name .. " has no configurable options", vim.log.levels.INFO)
    if on_close then
      on_close()
    end
    return
  end

  local sel = M.get_selected(agent_name)

  local function format_item(opt)
    local cur = sel[opt.name]
    local right
    if opt.kind == "toggle" then
      right = cur and "[x]" or "[ ]"
    elseif opt.kind == "opt_value" then
      if cur == true then
        right = "[bare]"
      elseif type(cur) == "string" and cur ~= "" then
        right = "= " .. cur
      else
        right = "[ ]"
      end
    else
      right = (cur and cur ~= "") and ("= " .. tostring(cur)) or "(unset)"
    end
    local display = opt.label or opt.flag
    return string.format("%-12s  %-40s  %s", right, display, opt.kind)
  end

  local ok_snacks, snacks = pcall(require, "snacks")
  if not (ok_snacks and snacks.picker) then
    vim.notify("harness: snacks.picker unavailable", vim.log.levels.WARN)
    if on_close then
      on_close()
    end
    return
  end

  local items = {}
  for i, opt in ipairs(schema) do
    table.insert(items, { idx = i, opt = opt, text = format_item(opt) })
  end
  table.insert(items, { idx = -1, opt = nil, text = string.format("%-12s  %s", "", "→ Continue (submit options)") })

  local function reopen()
    M.configure(agent_name, on_close)
  end

  snacks.picker.pick({
    source = "harness_options_" .. agent_name,
    items = items,
    format = function(item)
      return { { item.text, "Normal" } }
    end,
    title = "Options — " .. agent_name,
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      if not item or not item.opt then
        if on_close then
          on_close()
        end
        return
      end
      local opt = item.opt
      if opt.kind == "toggle" then
        M.toggle(agent_name, opt.name)
        vim.schedule(reopen)
        return
      end
      if opt.kind == "enum" and opt.choices then
        local choices = { "(unset)" }
        vim.list_extend(choices, opt.choices)
        vim.ui.select(choices, { prompt = (opt.label or opt.flag) .. ": " }, function(choice)
          if choice then
            M.set(agent_name, opt.name, choice ~= "(unset)" and choice or nil)
          end
          vim.schedule(reopen)
        end)
        return
      end
      if opt.kind == "opt_value" then
        local modes = { "off", "bare flag", "set value…" }
        vim.ui.select(modes, { prompt = (opt.label or opt.flag) .. ": " }, function(mode)
          if mode == "off" then
            M.set(agent_name, opt.name, nil)
          elseif mode == "bare flag" then
            M.set(agent_name, opt.name, true)
          elseif mode == "set value…" then
            local cur = sel[opt.name]
            vim.ui.input({
              prompt = (opt.prompt or opt.flag) .. ": ",
              default = type(cur) == "string" and cur or "",
            }, function(value)
              if value ~= nil then
                M.set(agent_name, opt.name, value ~= "" and value or nil)
              end
              vim.schedule(reopen)
            end)
            return
          end
          vim.schedule(reopen)
        end)
        return
      end
      if opt.picker_source then
        require("harness.sessions").list(opt.picker_source, function(value)
          if value ~= nil then
            M.set(agent_name, opt.name, value)
          end
          vim.schedule(reopen)
        end)
        return
      end
      vim.ui.input({
        prompt = (opt.prompt or opt.flag) .. ": ",
        default = sel[opt.name] and tostring(sel[opt.name]) or "",
      }, function(value)
        if value ~= nil then
          M.set(agent_name, opt.name, value ~= "" and value or nil)
        end
        vim.schedule(reopen)
      end)
    end,
    actions = {
      reset_all = function(picker)
        picker:close()
        M.reset(agent_name)
        vim.schedule(reopen)
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-r>"] = { "reset_all", mode = { "i", "n" } },
        },
      },
    },
  })
end

return M
