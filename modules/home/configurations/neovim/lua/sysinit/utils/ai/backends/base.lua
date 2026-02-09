-- Base utilities for tmux session management
-- Shared between native and other tmux-based backends
local M = {}

-- Generate a unique session name based on terminal name and cwd
-- @param termname string: Terminal name (e.g., "claude", "goose")
-- @param cwd string: Working directory
-- @return string: Session name (e.g., "ai-claude-abc123")
function M.get_session_name(termname, cwd)
  -- Create a hash of the cwd to keep session names unique per directory
  local cwd_hash = vim.fn.sha256(cwd):sub(1, 6)
  return string.format("ai-%s-%s", termname, cwd_hash)
end

-- Check if a tmux session exists
-- @param session_name string: Session name to check
-- @return boolean: True if session exists
function M.tmux_session_exists(session_name)
  vim.fn.system(string.format("tmux has-session -t %s 2>/dev/null", vim.fn.shellescape(session_name)))
  return vim.v.shell_error == 0
end

-- Find an existing tmux session for this terminal/cwd combo
-- @param termname string: Terminal name
-- @param cwd string: Working directory
-- @return string|nil: Session name if found, nil otherwise
function M.find_existing_session(termname, cwd)
  local session_name = M.get_session_name(termname, cwd)
  if M.tmux_session_exists(session_name) then
    return session_name
  end
  return nil
end

-- Build environment variables string for tmux
-- @param env table: Environment variables map
-- @return string: Space-separated env var assignments
local function build_env_string(env)
  local env_parts = {}
  for key, value in pairs(env) do
    table.insert(env_parts, string.format("%s=%s", key, vim.fn.shellescape(value)))
  end
  return table.concat(env_parts, " ")
end

-- Build the full command to run inside tmux
-- @param agent_config table: Agent configuration with cmd field
-- @param env table: Environment variables
-- @return string: The command to run
local function build_agent_command(agent_config, env)
  local cmd_parts = {}

  -- Add environment variables
  local env_str = build_env_string(env)
  if env_str ~= "" then
    table.insert(cmd_parts, env_str)
  end

  -- Add the agent command
  table.insert(cmd_parts, agent_config.cmd)

  return table.concat(cmd_parts, " ")
end

-- Build tmux command to create new session or attach to existing
-- @param session_name string: Session name
-- @param cwd string: Working directory
-- @param agent_config table: Agent configuration
-- @param env table: Environment variables
-- @param is_new boolean: True if creating new session, false if attaching
-- @return string: Complete tmux command
function M.build_tmux_command(session_name, cwd, agent_config, env, is_new)
  if is_new then
    -- Create new tmux session
    local agent_cmd = build_agent_command(agent_config, env)
    return string.format(
      "tmux new-session -s %s -c %s %s",
      vim.fn.shellescape(session_name),
      vim.fn.shellescape(cwd),
      vim.fn.shellescape(agent_cmd)
    )
  else
    -- Attach to existing session
    return string.format("tmux attach-session -t %s", vim.fn.shellescape(session_name))
  end
end

-- List all AI-related tmux sessions
-- @return table: List of session names
function M.list_ai_sessions()
  local result = vim.fn.system("tmux list-sessions -F '#{session_name}' 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local sessions = {}
  for session_name in result:gmatch("[^\r\n]+") do
    if session_name:match("^ai%-") then
      table.insert(sessions, session_name)
    end
  end
  return sessions
end

-- Kill a tmux session
-- @param session_name string: Session name to kill
-- @return boolean: True if successful
function M.kill_session(session_name)
  vim.fn.system(string.format("tmux kill-session -t %s 2>/dev/null", vim.fn.shellescape(session_name)))
  return vim.v.shell_error == 0
end

-- Get session information
-- @param session_name string: Session name
-- @return table|nil: Session info (name, windows, panes, etc.)
function M.get_session_info(session_name)
  if not M.tmux_session_exists(session_name) then
    return nil
  end

  local cmd = string.format(
    "tmux list-sessions -F '#{session_name}|#{session_windows}|#{session_attached}' 2>/dev/null | grep '^%s|'",
    session_name
  )
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return nil
  end

  local name, windows, attached = result:match("([^|]+)|([^|]+)|([^|]+)")
  return {
    name = name,
    windows = tonumber(windows) or 0,
    attached = tonumber(attached) or 0,
  }
end

return M
