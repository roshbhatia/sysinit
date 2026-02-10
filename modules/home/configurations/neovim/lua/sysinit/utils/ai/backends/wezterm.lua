-- WezTerm backend implementation with tmux persistence
local M = {}

local base = require("sysinit.utils.ai.backends.base")
local config = {}
local parent_pane_id = nil

-- Get the current WezTerm pane ID
-- @return number|nil: Pane ID or nil if not in WezTerm
local function get_current_pane_id()
  return tonumber(vim.env.WEZTERM_PANE)
end

-- Get information about a specific pane
-- @param pane_id number: Pane ID
-- @return table|nil: Pane info or nil if not found
local function get_pane_info(pane_id)
  if not pane_id then
    return nil
  end

  local result = vim.fn.system("wezterm cli list --format json 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local ok, panes = pcall(vim.fn.json_decode, result)
  if not ok or not panes then
    return nil
  end

  for _, pane in ipairs(panes) do
    if pane.pane_id == pane_id then
      return pane
    end
  end

  return nil
end

-- Check if a pane exists and is in the same window/tab as parent
-- @param pane_id number: Pane ID to check
-- @return boolean: True if pane exists
local function pane_exists(pane_id)
  local pane_info = get_pane_info(pane_id)
  if not pane_info then
    return false
  end

  local parent_info = get_pane_info(parent_pane_id)
  if not parent_info then
    return true
  end

  return pane_info.window_id == parent_info.window_id and pane_info.tab_id == parent_info.tab_id
end

-- Wait for a pane to appear (polling)
-- @param pane_id number: Pane ID to wait for
-- @param max_retries number: Maximum number of retries
-- @return boolean: True if pane appeared
local function wait_for_pane(pane_id, max_retries)
  max_retries = max_retries or 5
  local retry = 0
  while retry < max_retries do
    if get_pane_info(pane_id) then
      return true
    end
    retry = retry + 1
    if retry < max_retries then
      vim.fn.system("sleep 0.1")
    end
  end
  return false
end

-- Activate a pane (bring it into focus)
-- @param pane_id number: Pane ID to activate
-- @return boolean: True if successful
local function activate_pane(pane_id)
  vim.fn.system(string.format("wezterm cli activate-pane --pane-id %d 2>/dev/null", pane_id))
  return vim.v.shell_error == 0
end

-- Kill a pane
-- @param pane_id number: Pane ID to kill
-- @return boolean: True if successful
local function kill_pane(pane_id)
  vim.fn.system(string.format("wezterm cli kill-pane --pane-id %d 2>/dev/null", pane_id))
  return vim.v.shell_error == 0
end

-- Initialize the WezTerm backend
-- @param opts table: Configuration options
function M.setup(opts)
  config = opts or {}
  parent_pane_id = get_current_pane_id()
  if not parent_pane_id then
    vim.notify("WezTerm backend: parent pane ID not available", vim.log.levels.WARN)
  end
end

-- Open a new terminal in a WezTerm pane with tmux session
-- @param termname string: Terminal name for session naming
-- @param agent_config table: Agent configuration
-- @param cwd string: Working directory
-- @return table|nil: Terminal data or nil on failure
function M.open(termname, agent_config, cwd)
  if not parent_pane_id then
    vim.notify("Cannot spawn AI terminal: parent pane ID not available", vim.log.levels.ERROR)
    return nil
  end

  local session_name
  local is_new = true

  local existing_session = base.find_existing_session(termname, cwd)
  if existing_session then
    session_name = existing_session
    is_new = false
  else
    session_name = base.get_session_name(termname, cwd)
  end

  local tmux_cmd = base.build_tmux_command(session_name, cwd, agent_config, config.env or {}, is_new)

  local spawn_cmd = string.format(
    "wezterm cli split-pane --pane-id %d --right --percent 50 --cwd %s -- %s 2>/dev/null",
    parent_pane_id,
    vim.fn.shellescape(cwd),
    vim.fn.shellescape(tmux_cmd)
  )

  local result = vim.fn.system(spawn_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to spawn pane", vim.log.levels.ERROR)
    return nil
  end

  local pane_id = tonumber(vim.trim(result))
  if not pane_id then
    vim.notify("Failed to parse pane ID from wezterm", vim.log.levels.ERROR)
    return nil
  end

  if not wait_for_pane(pane_id, 5) then
    return nil
  end

  return {
    pane_id = pane_id,
    session_name = session_name,
    cmd = agent_config.cmd,
    cwd = cwd,
  }
end

-- Focus an existing terminal
-- @param term_data table: Terminal data
-- @return boolean: True if successful
function M.focus(term_data)
  if not term_data.pane_id or not pane_exists(term_data.pane_id) then
    return false
  end

  activate_pane(term_data.pane_id)
  return true
end

-- Hide a terminal (kill pane, keep tmux session)
-- @param term_data table: Terminal data
function M.hide(term_data)
  if not term_data.pane_id then
    return
  end

  if not pane_exists(term_data.pane_id) then
    term_data.pane_id = nil
    return
  end

  kill_pane(term_data.pane_id)
  term_data.pane_id = nil

  if parent_pane_id then
    activate_pane(parent_pane_id)
  end
end

-- Show a hidden terminal (reattach to tmux session in new pane)
-- @param term_data table: Terminal data
-- @return table|nil: Updated terminal data or nil on failure
function M.show(term_data)
  if not parent_pane_id then
    return nil
  end

  if not base.tmux_session_exists(term_data.session_name) then
    return nil
  end

  local tmux_cmd = string.format("tmux attach-session -t %s", vim.fn.shellescape(term_data.session_name))

  local spawn_cmd = string.format(
    "wezterm cli split-pane --pane-id %d --right --percent 50 --cwd %s -- %s 2>/dev/null",
    parent_pane_id,
    vim.fn.shellescape(term_data.cwd),
    vim.fn.shellescape(tmux_cmd)
  )

  local result = vim.fn.system(spawn_cmd)

  if vim.v.shell_error ~= 0 then
    return nil
  end

  local pane_id = tonumber(vim.trim(result))
  if not pane_id or not wait_for_pane(pane_id, 5) then
    return nil
  end

  term_data.pane_id = pane_id
  return term_data
end

-- Check if terminal is visible
-- @param term_data table: Terminal data
-- @return boolean: True if visible
function M.is_visible(term_data)
  if not term_data or not term_data.pane_id then
    return false
  end
  return pane_exists(term_data.pane_id)
end

-- Kill a terminal pane and its tmux session
-- @param term_data table: Terminal data
function M.kill(term_data)
  if term_data.pane_id then
    kill_pane(term_data.pane_id)
  end
  if term_data.session_name then
    base.kill_session(term_data.session_name)
  end
end

-- Cleanup all terminals on exit
-- @param terminals table: Map of terminal name to terminal data
function M.cleanup_all(terminals)
  for _, term_data in pairs(terminals) do
    if term_data.pane_id then
      kill_pane(term_data.pane_id)
    end
    if term_data.session_name then
      base.kill_session(term_data.session_name)
    end
  end
end

return M
