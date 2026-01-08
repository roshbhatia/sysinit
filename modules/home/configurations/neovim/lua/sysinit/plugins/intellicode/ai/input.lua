local M = {}
local context = require("sysinit.plugins.intellicode.ai.context")

local history_dir = "/tmp"
local history_files = {}

local function get_history_file(termname)
  if not history_files[termname] then
    history_files[termname] = string.format("%s/ai-terminals-history-%s.txt", history_dir, termname)
  end
  return history_files[termname]
end

local function save_to_history(termname, prompt)
  if not prompt or prompt == "" then
    return
  end

  local history_file = get_history_file(termname)
  local file = io.open(history_file, "a")
  if file then
    file:write(string.format("%s|%s\n", os.date("%Y-%m-%d %H:%M:%S"), prompt))
    file:close()
  end
end

local function load_history(termname)
  local history_file = get_history_file(termname)
  local history = {}
  local file = io.open(history_file, "r")
  if file then
    for line in file:lines() do
      local timestamp, prompt = line:match("^(.-)|(.*)")
      if timestamp and prompt then
        table.insert(history, { timestamp = timestamp, prompt = prompt })
      end
    end
    file:close()
  end
  return history
end

function M.create_history_picker(termname)
  local history_data = {}

  if termname then
    local history = load_history(termname)
    for _, entry in ipairs(history) do
      table.insert(history_data, {
        display = string.format("[%s] %s", entry.timestamp, entry.prompt),
        prompt = entry.prompt,
        terminal = termname,
        timestamp = entry.timestamp,
      })
    end
  else
    local agents = { "opencode", "goose", "claude", "cursor" }
    for _, agent in ipairs(agents) do
      local history = load_history(agent)
      for _, entry in ipairs(history) do
        table.insert(history_data, {
          display = string.format("[%s] %s: %s", agent, entry.timestamp, entry.prompt),
          prompt = entry.prompt,
          terminal = agent,
          timestamp = entry.timestamp,
        })
      end
    end

    table.sort(history_data, function(a, b)
      return a.timestamp > b.timestamp
    end)
  end

  if #history_data == 0 then
    vim.notify("No history available", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, entry in ipairs(history_data) do
    table.insert(items, entry.display)
  end

  vim.ui.select(items, {
    prompt = termname and (termname .. " History") or "AI Terminals History",
    format_item = function(item)
      return item
    end,
  }, function(choice, idx)
    if choice and idx then
      local selected = history_data[idx]
      vim.fn.setreg("+", selected.prompt)
      vim.notify("Copied to clipboard: " .. selected.prompt:sub(1, 50) .. "...", vim.log.levels.INFO)
    end
  end)
end

function M.create_input(termname, agent_icon, opts)
  local prompt = string.format("%s  %s: ", agent_icon, opts.action)
  local initial_state = context.current_position()
  local hist = load_history(termname)
  local current_index = #hist + 1

  vim.ui.input({
    prompt = prompt,
    default = opts.default,
  }, function(value)
    if value and value ~= "" then
      save_to_history(termname, value)
      opts.on_confirm(context.apply_placeholders(value, initial_state))
    end
  end)

  vim.defer_fn(function()
    local buf = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
    local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })

    if vim.api.nvim_buf_is_valid(buf) and (buftype == "prompt" or ft == "snacks_input") then
      vim.bo[buf].filetype = "ai_terminals_input"
      vim.wo.relativenumber = true
      vim.wo.number = true
      vim.wo.wrap = true
      vim.wo.linebreak = true
      vim.opt_local.textwidth = 80
      vim.opt_local.columns = 80

      vim.api.nvim_buf_call(buf, function()
        vim.fn.matchadd("Special", "[@!]\\w\\+")
      end)

      vim.keymap.set("i", "<C-j>", function()
        if current_index < #hist then
          current_index = current_index + 1
          local entry = hist[current_index]
          if entry then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { entry.prompt })
            vim.api.nvim_win_set_cursor(0, { 1, #entry.prompt })
          end
        end
      end, { buffer = buf, silent = true })

      vim.keymap.set("i", "<C-k>", function()
        if current_index > 1 then
          current_index = current_index - 1
          local entry = hist[current_index]
          if entry then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { entry.prompt })
            vim.api.nvim_win_set_cursor(0, { 1, #entry.prompt })
          end
        elseif current_index == 1 then
          current_index = #hist + 1
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
          vim.api.nvim_win_set_cursor(0, { 1, 0 })
        end
      end, { buffer = buf, silent = true })
    end
  end, 50)
end

return M
