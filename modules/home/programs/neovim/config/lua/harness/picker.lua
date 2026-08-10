local M = {}

local function active_adapter()
  local session = require("harness.session")
  local registry = require("harness.registry")
  local name = session.get_active()
  if not name then
    return nil
  end
  return registry.get_by_name(name)
end

local function activate(adapter)
  require("harness.session").set_active(adapter.name)
  require("harness.frecency").record(adapter.name)
  pcall(adapter.toggle)
end

local function format_label(adapter)
  local options = require("harness.options")
  local session = require("harness.session")
  local current = session.get_active()
  local suffix = adapter.name == current and "  (active)" or ""
  local summary = options.summary(adapter.name)
  if summary ~= "" then
    suffix = suffix .. "  [" .. summary .. "]"
  end
  return adapter.label .. suffix
end

local function snacks_picker()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.picker then
    return snacks
  end
  return nil
end

local function fallback_select(adapters)
  vim.ui.select(adapters, {
    prompt = "Select agent:",
    format_item = format_label,
  }, function(adapter)
    if adapter then
      activate(adapter)
    end
  end)
end

function M.pick_agent()
  local registry = require("harness.registry")

  local active = active_adapter()
  if active then
    local ok, visible = pcall(active.is_visible)
    if ok and visible then
      pcall(active.toggle)
      return
    end
    if pcall(active.focus) then
      return
    end
  end

  local available = registry.get_all_available()
  if #available == 0 then
    vim.notify("Harness: no agents available on PATH", vim.log.levels.WARN)
    return
  end

  require("harness.frecency").sort(available)

  local snacks = snacks_picker()
  if not snacks then
    fallback_select(available)
    return
  end

  local items = {}
  for _, adapter in ipairs(available) do
    table.insert(items, { adapter = adapter, text = format_label(adapter) })
  end

  snacks.picker.pick({
    source = "harness_agents",
    items = items,
    title = "Select agent  (<c-o> for options)",
    format = function(item)
      return { { item.text, "Normal" } }
    end,
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      if item then
        activate(item.adapter)
      end
    end,
    actions = {
      open_options = function(picker, item)
        if not item then
          return
        end
        local agent_name = item.adapter.name
        picker:close()
        require("harness.options").configure(agent_name, function()
          vim.schedule(M.pick_agent)
        end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-o>"] = { "open_options", mode = { "i", "n" } },
        },
      },
      list = {
        keys = {
          ["<c-o>"] = "open_options",
        },
      },
    },
  })
end

function M.kill_active()
  local session = require("harness.session")
  local adapter = active_adapter()
  if adapter and adapter.kill then
    pcall(adapter.kill)
  elseif adapter then
    pcall(adapter.toggle)
  end
  session.clear_active()
end

function M.kill_and_pick()
  M.kill_active()
  M.pick_agent()
end

return M
