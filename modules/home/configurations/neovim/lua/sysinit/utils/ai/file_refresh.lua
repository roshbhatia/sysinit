---@mod sysinit.utils.ai.file_refresh File refresh functionality for AI terminals
---@brief [[
--- This module provides file refresh functionality to detect and reload files
--- that have been modified by AI terminals (opencode, claude, cursor, etc.).
--- Since AI terminals now run as WezTerm panes (not neovim terminal buffers),
--- we simply monitor for external file changes more aggressively.
---@brief ]]

local M = {}

--- Timer for checking file changes
--- @type userdata|nil
local refresh_timer = nil

--- Setup autocommands for file change detection
--- @param config table The plugin configuration
function M.setup(config)
  config = config or {}
  local refresh_config = config.file_refresh or {}

  if not refresh_config.enable then
    return
  end

  local augroup = vim.api.nvim_create_augroup("AITerminalFileRefresh", { clear = true })

  -- Check for file changes on various events
  vim.api.nvim_create_autocmd({
    "CursorHold",
    "CursorHoldI",
    "FocusGained",
    "BufEnter",
    "InsertLeave",
    "TextChanged",
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
        vim.cmd("silent! checktime")
      end)
    )
  end

  -- Set a shorter updatetime for more responsive file change detection
  if refresh_config.updatetime then
    vim.o.updatetime = refresh_config.updatetime
  end
end

return M
