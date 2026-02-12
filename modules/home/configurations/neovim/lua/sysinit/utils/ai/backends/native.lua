-- Native Neovim splits backend implementation using snacks.nvim
local M = {}

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
  -- Build environment variables
  local env = vim.tbl_extend("force", config.env or {}, {
    NVIM_SOCKET_PATH = vim.env.NVIM_SOCKET_PATH,
  })

  -- Open terminal in right split using snacks.nvim
  local term = Snacks.terminal.open(agent_config.cmd, {
    cwd = cwd,
    env = env,
    win = {
      position = "right",
      width = 0.5, -- 50% width
    },
  })

  return {
    buf = term.buf,
    win = term.win,
    term = term, -- Store full terminal object
    cmd = agent_config.cmd,
    cwd = cwd,
    name = termname,
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

-- Hide a terminal (close window)
-- @param term_data table: Terminal data
function M.hide(term_data)
  if term_data.win and vim.api.nvim_win_is_valid(term_data.win) then
    vim.api.nvim_win_close(term_data.win, true)
  end
  term_data.win = nil
  term_data.buf = nil
  term_data.term = nil
end

-- Show a hidden terminal (not supported - need to reopen)
-- @param term_data table: Terminal data
-- @return table|nil: nil (not supported)
function M.show(term_data)
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
