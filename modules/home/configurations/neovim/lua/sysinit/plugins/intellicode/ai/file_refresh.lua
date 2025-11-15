---@mod sysinit.plugins.intellicode.ai.file_refresh File refresh functionality for AI terminals
---@brief [[
--- This module provides file refresh functionality to detect and reload files
--- that have been modified by AI terminals (opencode, claude, cursor, etc.).
--- Adapted from claude-code.nvim's file_refresh.lua for general AI terminal use.
---@brief ]]

local M = {}

--- Timer for checking file changes
--- @type userdata|nil
local refresh_timer = nil

--- List of AI terminal patterns to monitor
local ai_terminal_patterns = {
  "opencode",
  "claude%-code",
  "cursor%-agent",
  "copilot",
}

--- Check if current buffer is an AI terminal
--- @return boolean
local function is_ai_terminal()
  local buf_name = vim.api.nvim_buf_get_name(0)
  for _, pattern in ipairs(ai_terminal_patterns) do
    if buf_name:match(pattern) then
      return true
    end
  end
  return false
end

--- Check if any AI terminal is currently active
--- @return boolean
local function has_active_ai_terminal()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buf_name = vim.api.nvim_buf_get_name(buf)
    for _, pattern in ipairs(ai_terminal_patterns) do
      if buf_name:match(pattern) then
        return true
      end
    end
  end
  return false
end

--- Setup autocommands for file change detection
--- @param config table The plugin configuration
function M.setup(config)
  config = config or {}
  local refresh_config = config.file_refresh or {}

  if not refresh_config.enable then
    return
  end

  local augroup = vim.api.nvim_create_augroup("AITerminalFileRefresh", { clear = true })

  -- Create an autocommand that checks for file changes more frequently
  vim.api.nvim_create_autocmd({
    "CursorHold",
    "CursorHoldI",
    "FocusGained",
    "BufEnter",
    "InsertLeave",
    "TextChanged",
    "TermLeave",
    "TermEnter",
    "BufWinEnter",
  }, {
    group = augroup,
    pattern = "*",
    callback = function()
      if vim.fn.filereadable(vim.fn.expand("%")) == 1 then
        vim.cmd("checktime")
      end
    end,
    desc = "Check for file changes on disk",
  })

  -- Clean up any existing timer
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end

  -- Create a timer to check for file changes periodically
  refresh_timer = vim.loop.new_timer()
  if refresh_timer then
    refresh_timer:start(
      0,
      refresh_config.timer_interval or 1000,
      vim.schedule_wrap(function()
        -- Only check time if there's an active AI terminal
        if has_active_ai_terminal() then
          vim.cmd("silent! checktime")
        end
      end)
    )
  end

  -- Create an autocommand that notifies when a file has been changed externally
  if refresh_config.show_notifications then
    vim.api.nvim_create_autocmd("FileChangedShellPost", {
      group = augroup,
      pattern = "*",
      callback = function()
        vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
      end,
      desc = "Notify when a file is changed externally",
    })
  end

  -- Set a shorter updatetime while AI terminals are open
  vim.g.ai_terminals_saved_updatetime = vim.o.updatetime

  -- When AI terminal opens, set a shorter updatetime
  vim.api.nvim_create_autocmd("TermOpen", {
    group = augroup,
    pattern = "*",
    callback = function()
      if is_ai_terminal() then
        vim.g.ai_terminals_saved_updatetime = vim.o.updatetime
        vim.o.updatetime = refresh_config.updatetime or 100
      end
    end,
    desc = "Set shorter updatetime when AI terminal is open",
  })

  -- When AI terminal closes, restore normal updatetime
  vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    pattern = "*",
    callback = function()
      if is_ai_terminal() then
        vim.o.updatetime = vim.g.ai_terminals_saved_updatetime
      end
    end,
    desc = "Restore normal updatetime when AI terminal is closed",
  })
end

--- Clean up the file refresh functionality (stop the timer)
function M.cleanup()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end
end

return M
