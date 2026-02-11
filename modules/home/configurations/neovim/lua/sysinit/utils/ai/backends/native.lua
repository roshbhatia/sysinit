-- Native Neovim splits backend implementation using snacks.nvim
local M = {}

local base = require("sysinit.utils.ai.backends.base")
local config = {}

-- Initialize the native backend
-- @param opts table: Configuration options
function M.setup(opts)
  config = opts or {}
end

-- Open a new terminal in a native Neovim split
-- @param termname string: Terminal name
-- @param agent_config table: Agent configuration
-- @param cwd string: Working directory
-- @return table|nil: Terminal data or nil on failure
function M.open(termname, agent_config, cwd)
  local session_name = base.find_existing_session(termname, cwd)
  local is_new = not session_name

  if not session_name then
    session_name = base.get_session_name(termname, cwd)
  end

  local tmux_cmd = base.build_tmux_command(session_name, cwd, agent_config, config.env or {}, is_new)

  -- Open terminal in right split using snacks.nvim
  local term = Snacks.terminal.open(tmux_cmd, {
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
    session_name = session_name,
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

-- Hide a terminal (close window, keep tmux session)
-- @param term_data table: Terminal data
function M.hide(term_data)
  if term_data.win and vim.api.nvim_win_is_valid(term_data.win) then
    vim.api.nvim_win_close(term_data.win, true)
  end
  term_data.win = nil
  term_data.buf = nil
  term_data.term = nil
end

-- Show a hidden terminal (reattach to tmux session in new window)
-- @param term_data table: Terminal data
-- @return table|nil: Updated terminal data or nil on failure
function M.show(term_data)
  if not base.tmux_session_exists(term_data.session_name) then
    return nil
  end

  local tmux_cmd = string.format("tmux attach-session -t %s", vim.fn.shellescape(term_data.session_name))

  local term = Snacks.terminal.open(tmux_cmd, {
    cwd = term_data.cwd,
    win = {
      position = "right",
      width = 0.5,
    },
  })

  term_data.buf = term.buf
  term_data.win = term.win
  term_data.term = term

  return term_data
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

-- Kill the tmux session completely
-- @param term_data table: Terminal data
function M.kill_session(term_data)
  if term_data.session_name and base.tmux_session_exists(term_data.session_name) then
    vim.fn.system(string.format("tmux kill-session -t %s 2>/dev/null", vim.fn.shellescape(term_data.session_name)))
  end
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
