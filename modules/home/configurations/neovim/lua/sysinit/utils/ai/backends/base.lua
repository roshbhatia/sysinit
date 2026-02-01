-- Shared tmux utilities used by both backends
local M = {}

-- Generate a unique tmux session name for a terminal
-- @param termname string: Name of the terminal (e.g., "claude", "copilot")
-- @param cwd string: Current working directory
-- @return string: Tmux session name
function M.get_session_name(termname, cwd)
  -- Use full, sanitized path to avoid collisions
  local full = vim.fn.fnamemodify(cwd, ":p")
  local safe = full:gsub("[/:%s]", "_")
  local timestamp = os.date("%Y%m%d-%H%M%S")
  return string.format("ai-%s-%s-%s", termname, safe, timestamp)
end

-- Find an existing tmux session for this terminal and directory
-- @param termname string: Name of the terminal
-- @param cwd string: Current working directory
-- @return string|nil: Session name if found, nil otherwise
function M.find_existing_session(termname, cwd)
  -- Use full, sanitized path for prefix matching
  local full = vim.fn.fnamemodify(cwd, ":p")
  local safe = full:gsub("[/:%s]", "_")
  local prefix = string.format("ai-%s-%s-", termname, safe)
  local out = vim.fn.system("tmux list-sessions -F '#S' 2>/dev/null")
  if vim.v.shell_error ~= 0 or not out or out == "" then
    return nil
  end
  for s in string.gmatch(out, "[^\n]+") do
    local name = vim.trim(s)
    if vim.startswith(name, prefix) then
      return name
    end
  end
  return nil
end

-- Check if a tmux session exists
-- @param session_name string: Tmux session name
-- @return boolean: True if session exists
function M.tmux_session_exists(session_name)
  vim.fn.system(string.format("tmux has-session -t %s 2>/dev/null", vim.fn.shellescape(session_name)))
  return vim.v.shell_error == 0
end

-- Build the tmux command for creating or attaching to a session
-- @param session_name string: Tmux session name
-- @param cwd string: Working directory
-- @param agent_config table: Agent configuration with cmd field
-- @param env table: Environment variables to set
-- @param is_new boolean: Whether this is a new session
-- @return string: Complete tmux command
function M.build_tmux_command(session_name, cwd, agent_config, env, is_new)
  local env_str = ""
  for key, value in pairs(env) do
    env_str = env_str .. string.format("export %s=%s; ", key, vim.fn.shellescape(value))
  end

  if vim.env.NVIM_SOCKET_PATH then
    env_str = env_str .. string.format("export NVIM_SOCKET_PATH=%s; ", vim.fn.shellescape(vim.env.NVIM_SOCKET_PATH))
  end

  if is_new then
    return string.format(
      "tmux new-session -s %s -c %s 'tmux set-option -t %s status off; %s%s'",
      vim.fn.shellescape(session_name),
      vim.fn.shellescape(cwd),
      vim.fn.shellescape(session_name),
      env_str,
      agent_config.cmd
    )
  else
    return string.format("tmux attach-session -t %s", vim.fn.shellescape(session_name))
  end
end

-- Send text to a tmux session
-- @param session_name string: Tmux session name
-- @param text string: Text to send
-- @param opts table: Options with optional 'submit' field
function M.send_to_tmux(session_name, text, opts)
  opts = opts or {}

  if not M.tmux_session_exists(session_name) then
    return
  end

  local send_cmd = string.format("tmux send-keys -t %s %s", vim.fn.shellescape(session_name), vim.fn.shellescape(text))
  vim.fn.system(send_cmd)

  if opts.submit then
    vim.fn.system(string.format("tmux send-keys -t %s Enter", vim.fn.shellescape(session_name)))
  end
end

return M
