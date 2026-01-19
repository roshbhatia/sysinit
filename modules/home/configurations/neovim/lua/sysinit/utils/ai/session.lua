local M = {}

local config = {}
local terminals = {}
local active_terminal = nil
local augroup = nil
local parent_pane_id = nil

local function get_current_pane_id()
  return tonumber(vim.env.WEZTERM_PANE)
end

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

local function get_session_name(termname, cwd)
  -- Use full, sanitized path to avoid collisions
  local full = vim.fn.fnamemodify(cwd, ":p")
  local safe = full:gsub("[/:%s]", "_")
  local timestamp = os.date("%Y%m%d-%H%M%S")
  return string.format("ai-%s-%s-%s", termname, safe, timestamp)
end

local function find_existing_session(termname, cwd)
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

local function tmux_session_exists(session_name)
  vim.fn.system(string.format("tmux has-session -t %s 2>/dev/null", vim.fn.shellescape(session_name)))
  return vim.v.shell_error == 0
end

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

local function is_visible(termname)
  local term_data = terminals[termname]
  if not term_data or not term_data.pane_id then
    return false
  end
  return pane_exists(term_data.pane_id)
end

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

local function activate_pane(pane_id)
  vim.fn.system(string.format("wezterm cli activate-pane --pane-id %d 2>/dev/null", pane_id))
  return vim.v.shell_error == 0
end

local function kill_pane(pane_id)
  vim.fn.system(string.format("wezterm cli kill-pane --pane-id %d 2>/dev/null", pane_id))
  return vim.v.shell_error == 0
end

function M.setup(opts)
  config = opts or {}
  config.terminals = config.terminals or {}
  config.env = config.env or {}

  parent_pane_id = get_current_pane_id()
  if not parent_pane_id then
    vim.notify("Warning: Not running inside WezTerm. AI terminal features disabled.", vim.log.levels.WARN)
    return
  end

  if not augroup then
    augroup = vim.api.nvim_create_augroup("AIManager", { clear = true })

    vim.api.nvim_create_autocmd("CursorHold", {
      group = augroup,
      callback = function()
        for _, term_data in pairs(terminals) do
          if term_data.pane_id and not pane_exists(term_data.pane_id) then
            term_data.pane_id = nil
          end
        end
      end,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = augroup,
      callback = function()
        for _, term_data in pairs(terminals) do
          if term_data.pane_id then
            kill_pane(term_data.pane_id)
          end
        end
      end,
    })
  end
end

function M.open(termname)
  local agent_config = config.terminals[termname]
  if not agent_config then
    vim.notify(string.format("Unknown terminal: %s. Check session.setup() config", termname), vim.log.levels.ERROR)
    return
  end

  if is_visible(termname) then
    M.focus(termname)
    return
  end

  if not parent_pane_id then
    vim.notify("Cannot spawn AI terminal: parent pane ID not available", vim.log.levels.ERROR)
    return
  end

  local agents = require("sysinit.utils.ai.agents")
  local agent = agents.get_by_name(termname)
  local cwd = vim.fn.getcwd()

  local session_name = find_existing_session(termname, cwd)
  local is_new_session = false

  if not session_name then
    session_name = get_session_name(termname, cwd)
    is_new_session = true
  end

  local env_str = ""
  for key, value in pairs(config.env) do
    env_str = env_str .. string.format("export %s=%s; ", key, vim.fn.shellescape(value))
  end

  if vim.env.NVIM_SOCKET_PATH then
    env_str = env_str .. string.format("export NVIM_SOCKET_PATH=%s; ", vim.fn.shellescape(vim.env.NVIM_SOCKET_PATH))
  end

  local tmux_cmd
  if is_new_session then
    tmux_cmd = string.format(
      "tmux new-session -s %s -c %s 'tmux set-option -t %s status off; %s%s'",
      vim.fn.shellescape(session_name),
      vim.fn.shellescape(cwd),
      vim.fn.shellescape(session_name),
      env_str,
      agent_config.cmd
    )
  else
    tmux_cmd = string.format("tmux attach-session -t %s", vim.fn.shellescape(session_name))
  end

  local spawn_cmd = string.format(
    "wezterm cli split-pane --pane-id %d --right --percent 50 --cwd %s -- %s 2>/dev/null",
    parent_pane_id,
    vim.fn.shellescape(cwd),
    tmux_cmd
  )

  local result = vim.fn.system(spawn_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to spawn pane", vim.log.levels.ERROR)
    return
  end

  local pane_id = tonumber(vim.trim(result))
  if not pane_id then
    vim.notify("Failed to parse pane ID from wezterm", vim.log.levels.ERROR)
    return
  end

  if not wait_for_pane(pane_id, 5) then
    return
  end

  terminals[termname] = {
    pane_id = pane_id,
    session_name = session_name,
    cmd = agent_config.cmd,
    cwd = cwd,
  }
  active_terminal = termname
end

function M.toggle(termname)
  local term_data = terminals[termname]

  if term_data and pane_exists(term_data.pane_id) then
    M.focus(termname)
  else
    M.open(termname)
  end
end

function M.focus(termname)
  local term_data = terminals[termname]

  if not term_data then
    vim.notify(string.format("Terminal not found: %s. Use open() first", termname), vim.log.levels.WARN)
    return
  end

  if not term_data.pane_id or not pane_exists(term_data.pane_id) then
    vim.notify(string.format("Pane no longer exists for %s. Reopening...", termname), vim.log.levels.WARN)
    term_data.pane_id = nil
    M.open(termname)
    return
  end

  activate_pane(term_data.pane_id)
  active_terminal = termname
end

function M.hide(termname)
  local term_data = terminals[termname]

  if not term_data or not term_data.pane_id then
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

function M.show(termname)
  local term_data = terminals[termname]

  if not term_data then
    vim.notify(string.format("Terminal not found: %s", termname), vim.log.levels.WARN)
    return
  end

  if not tmux_session_exists(term_data.session_name) then
    vim.notify(string.format("Session no longer exists for %s. Reopening...", termname), vim.log.levels.WARN)
    terminals[termname] = nil
    M.open(termname)
    return
  end

  if is_visible(termname) then
    M.focus(termname)
    return
  end

  local tmux_cmd = string.format("tmux attach-session -t %s", vim.fn.shellescape(term_data.session_name))

  local spawn_cmd = string.format(
    "wezterm cli split-pane --pane-id %d --right --percent 50 --cwd %s -- %s 2>/dev/null",
    parent_pane_id,
    vim.fn.shellescape(term_data.cwd),
    tmux_cmd
  )

  local result = vim.fn.system(spawn_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to spawn pane", vim.log.levels.ERROR)
    return
  end

  local pane_id = tonumber(vim.trim(result))
  if not pane_id then
    vim.notify("Failed to parse pane ID from wezterm", vim.log.levels.ERROR)
    return
  end

  if not wait_for_pane(pane_id, 5) then
    return
  end

  term_data.pane_id = pane_id
  active_terminal = termname
end

function M.is_visible(termname)
  return is_visible(termname)
end

function M.send(termname, text, opts)
  opts = opts or {}
  local term_data = terminals[termname]

  if not term_data then
    vim.notify(string.format("Terminal not found: %s. Open it first", termname), vim.log.levels.ERROR)
    return
  end

  if not tmux_session_exists(term_data.session_name) then
    vim.notify(string.format("Session no longer exists for %s", termname), vim.log.levels.ERROR)
    return
  end

  local send_cmd =
    string.format("tmux send-keys -t %s %s", vim.fn.shellescape(term_data.session_name), vim.fn.shellescape(text))
  vim.fn.system(send_cmd)

  if opts.submit then
    vim.fn.system(string.format("tmux send-keys -t %s Enter", vim.fn.shellescape(term_data.session_name)))
  end
end

function M.get_info(termname)
  local term_data = terminals[termname]

  if not term_data then
    return nil
  end

  return {
    name = termname,
    visible = is_visible(termname),
    pane_id = term_data.pane_id,
    session_name = term_data.session_name,
    cmd = term_data.cmd,
    cwd = term_data.cwd,
  }
end

function M.get_all()
  local result = {}
  for name, _ in pairs(terminals) do
    result[name] = M.get_info(name)
  end
  return result
end

function M.exists(termname)
  local term_data = terminals[termname]
  if not term_data then
    return false
  end
  return tmux_session_exists(term_data.session_name)
end

function M.close(termname)
  local term_data = terminals[termname]

  if not term_data then
    return
  end

  if term_data.pane_id then
    kill_pane(term_data.pane_id)
  end

  if tmux_session_exists(term_data.session_name) then
    vim.fn.system(string.format("tmux kill-session -t %s", vim.fn.shellescape(term_data.session_name)))
  end

  terminals[termname] = nil
  if active_terminal == termname then
    active_terminal = nil
  end
end

function M.cleanup_terminal(termname)
  terminals[termname] = nil
  if active_terminal == termname then
    active_terminal = nil
  end
end

function M.get_active()
  return active_terminal
end

function M.set_active(termname)
  if terminals[termname] then
    active_terminal = termname
  end
end

function M.activate(termname)
  local term_data = terminals[termname]

  if not term_data then
    M.open(termname)
  else
    if is_visible(termname) then
      M.focus(termname)
    else
      M.show(termname)
    end
    active_terminal = termname
  end
end

function M.send_to_active(text, opts)
  if not active_terminal then
    vim.notify("No active AI terminal", vim.log.levels.WARN)
    return
  end
  M.send(active_terminal, text, opts)
end

function M.ensure_active_and_send(text)
  if not active_terminal then
    vim.notify("No active AI terminal. Select one with <leader>jj", vim.log.levels.WARN)
    return
  end

  local term_info = M.get_info(active_terminal)
  if not term_info or not M.exists(active_terminal) then
    M.open(active_terminal)
    M.focus(active_terminal)

    vim.fn.system("sleep 0.2")
    if M.exists(active_terminal) then
      M.send(active_terminal, text, { submit = true })
    end
  else
    if not is_visible(active_terminal) then
      M.show(active_terminal)
      vim.fn.system("sleep 0.1")
    else
      M.focus(active_terminal)
    end
    M.send(active_terminal, text, { submit = true })
  end
end

return M
