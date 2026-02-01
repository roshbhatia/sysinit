-- Native Neovim splits backend implementation using snacks.nvim
local M = {}

local config = {}

-- Initialize the native backend
-- @param opts table: Configuration options
function M.setup(opts)
  config = opts or {}
end

-- Open a new terminal in a native Neovim split
-- @param _termname string: Terminal name (unused without tmux)
-- @param agent_config table: Agent configuration
-- @param cwd string: working directory
-- @return table|nil: Terminal data or nil on failure
function M.open(_termname, agent_config, cwd)
  -- Build environment setup
  local env_str = ""
  for key, value in pairs(config.env or {}) do
    env_str = env_str .. string.format("export %s=%s; ", key, vim.fn.shellescape(value))
  end

  if vim.env.NVIM_SOCKET_PATH then
    env_str = env_str .. string.format("export NVIM_SOCKET_PATH=%s; ", vim.fn.shellescape(vim.env.NVIM_SOCKET_PATH))
  end

  -- Run agent command directly without tmux (no persistence needed for Snacks)
  local cmd = env_str .. agent_config.cmd

  -- Open terminal in right split using snacks.nvim
  local term = Snacks.terminal.open(cmd, {
    cwd = cwd,
    win = {
      position = "right",
      width = 0.5, -- 50% width to match WezTerm
    },
  })

  return {
    buf = term.buf,
    win = term.win,
    term = term, -- Store full terminal object
    cmd = agent_config.cmd,
    cwd = cwd,
  }
end

-- Focus an existing terminal
-- @param term_data table: Terminal data
-- @return boolean: True if successful
function M.focus(term_data)
  if not M.is_visible(term_data) then
    return false
  end
  vim.api.nvim_set_current_win(term_data.win)
  return true
end

-- Hide a terminal (close window, no persistence without tmux)
-- @param term_data table: Terminal data
function M.hide(term_data)
  if term_data.win and vim.api.nvim_win_is_valid(term_data.win) then
    vim.api.nvim_win_close(term_data.win, true)
  end
  term_data.win = nil
  term_data.buf = nil
  term_data.term = nil
end

-- Show a hidden terminal (not supported without tmux persistence)
-- @param _term_data table: Terminal data (unused without tmux)
-- @return table|nil: Always returns nil (no persistence without tmux)
function M.show(_term_data)
  -- Without tmux, we can't restore terminal state
  -- User should create a new terminal instead
  return nil
end

-- Check if terminal is visible
-- @param term_data table: Terminal data
-- @return boolean: True if visible
function M.is_visible(term_data)
  return term_data and term_data.win and vim.api.nvim_win_is_valid(term_data.win)
end

-- Kill a terminal window
-- @param term_data table: Terminal data
function M.kill(term_data)
  if term_data.win and vim.api.nvim_win_is_valid(term_data.win) then
    vim.api.nvim_win_close(term_data.win, true)
  end
end

-- Cleanup all terminals on exit
-- @param terminals table: Map of terminal name to terminal data
function M.cleanup_all(terminals)
  for _, term_data in pairs(terminals) do
    if term_data.win and vim.api.nvim_win_is_valid(term_data.win) then
      vim.api.nvim_win_close(term_data.win, true)
    end
  end
end

return M
