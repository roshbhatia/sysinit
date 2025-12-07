-- modules/home/configurations/neovim/lua/sysinit/plugins/intellicode/ai/ai_manager.lua
-- AI terminal manager using tmux sessions for persistence + WezTerm panes for UI
-- Fixed: Removed all error suppression, added proper error handling, replaced defer with polling

local M = {}

local config = {}
local terminals = {}
local active_terminal = nil
local augroup = nil
local parent_pane_id = nil

-- Get the current WezTerm pane ID from environment
local function get_current_pane_id()
  return tonumber(vim.env.WEZTERM_PANE)
end

-- Get pane information from WezTerm - now with proper error handling
local function get_pane_info(pane_id)
  if not pane_id then
    return nil
  end

  local result = vim.fn.system("wezterm cli list --format json")
  if vim.v.shell_error ~= 0 then
    vim.notify(
      string.format("Failed to list wezterm panes: %s", vim.trim(result)),
      vim.log.levels.ERROR
    )
    return nil
  end

  local ok, panes = pcall(vim.fn.json_decode, result)
  if not ok then
    vim.notify(
      string.format("Failed to parse wezterm output: %s", tostring(panes)),
      vim.log.levels.ERROR
    )
    return nil
  end

  if not panes then
    return nil
  end

  for _, pane in ipairs(panes) do
    if pane.pane_id == pane_id then
      return pane
    end
  end

  return nil
end

-- Get tmux session name for an agent
-- Format: ai-<agent>-<folder>-<timestamp>
-- Example: ai-opencode-sysinit-20251205-123045
local function get_session_name(termname, cwd)
  local folder = vim.fn.fnamemodify(cwd, ":t") -- Get last component of path
  local timestamp = os.date("%Y%m%d-%H%M%S")
  return string.format("ai-%s-%s-%s", termname, folder, timestamp)
end

-- Find existing session for agent+folder combo (most recent)
local function find_existing_session(termname, cwd)
  local folder = vim.fn.fnamemodify(cwd, ":t")
  local prefix = string.format("ai-%s-%s-", termname, folder)

  local result = vim.fn.system("tmux list-sessions -F '#{session_name}'")
  if vim.v.shell_error ~= 0 then
    -- No sessions exist, this is not an error
    return nil
  end

  local sessions = {}
  for line in vim.gsplit(vim.trim(result), "\n") do
    if line:match("^" .. vim.pesc(prefix)) then
      table.insert(sessions, line)
    end
  end

  -- Return most recent (last in sorted list)
  if #sessions > 0 then
    table.sort(sessions)
    return sessions[#sessions]
  end

  return nil
end

-- Check if tmux session exists
local function tmux_session_exists(session_name)
  vim.fn.system(string.format("tmux has-session -t %s", vim.fn.shellescape(session_name)))
  return vim.v.shell_error == 0
end

-- Check if WezTerm pane exists and belongs to same window/tab
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

-- Check if terminal is visible (has active WezTerm pane)
local function is_visible(termname)
  local term_data = terminals[termname]
  if not term_data or not term_data.pane_id then
    return false
  end
  return pane_exists(term_data.pane_id)
end

-- Wait for pane to be created and available (polling with backoff)
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

-- Set tab title with proper error handling and retries
local function set_tab_title(pane_id, title)
  local result = vim.fn.system(
    string.format(
      "wezterm cli set-tab-title --pane-id %d %s",
      pane_id,
      vim.fn.shellescape(title)
    )
  )
  if vim.v.shell_error ~= 0 then
    vim.notify(
      string.format("Failed to set tab title: %s", vim.trim(result)),
      vim.log.levels.WARN
    )
    return false
  end
  return true
end

-- Activate pane with proper error handling
local function activate_pane(pane_id)
  local result = vim.fn.system(string.format("wezterm cli activate-pane --pane-id %d", pane_id))
  if vim.v.shell_error ~= 0 then
    vim.notify(
      string.format("Failed to activate pane %d: %s", pane_id, vim.trim(result)),
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

-- Kill pane with proper error handling
local function kill_pane(pane_id)
  local result = vim.fn.system(string.format("wezterm cli kill-pane --pane-id %d", pane_id))
  if vim.v.shell_error ~= 0 then
    vim.notify(
      string.format("Failed to kill pane %d: %s", pane_id, vim.trim(result)),
      vim.log.levels.WARN
    )
    return false
  end
  return true
end

function M.setup(opts)
  config = opts or {}
  config.terminals = config.terminals or {}
  config.env = config.env or {}

  parent_pane_id = get_current_pane_id()
  if not parent_pane_id then
    vim.notify(
      "ERROR: Not running inside WezTerm. AI terminal integration requires WezTerm.",
      vim.log.levels.ERROR
    )
    return
  end

  -- Validate parent pane actually exists
  if not get_pane_info(parent_pane_id) then
    vim.notify(
      "ERROR: Cannot find parent pane. WezTerm environment corrupted.",
      vim.log.levels.ERROR
    )
    parent_pane_id = nil
    return
  end

  if not augroup then
    augroup = vim.api.nvim_create_augroup("AIManager", { clear = true })

    -- Periodically clean up closed panes (but keep tmux sessions alive)
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

    -- Close all AI panes when neovim exits (tmux sessions persist)
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
    vim.notify(string.format("Unknown terminal: %s. Check ai_manager.setup() config", termname), vim.log.levels.ERROR)
    return
  end

  -- If already visible, just focus it
  if is_visible(termname) then
    M.focus(termname)
    return
  end

  if not parent_pane_id then
    vim.notify("Cannot spawn AI terminal: parent pane ID not available", vim.log.levels.ERROR)
    return
  end

  local agents = require("sysinit.plugins.intellicode.agents")
  local agent = agents.get_by_name(termname)
  local cwd = vim.fn.getcwd()

  -- Find existing session or create new one
  local session_name = find_existing_session(termname, cwd)
  local is_new_session = false

  if not session_name then
    session_name = get_session_name(termname, cwd)
    is_new_session = true
  end

  -- Build env vars string
  local env_str = ""
  for key, value in pairs(config.env) do
    env_str = env_str .. string.format("export %s=%s; ", key, vim.fn.shellescape(value))
  end

  -- Add NVIM_SOCKET_PATH to environment if available
  if vim.env.NVIM_SOCKET_PATH then
    env_str = env_str .. string.format("export NVIM_SOCKET_PATH=%s; ", vim.fn.shellescape(vim.env.NVIM_SOCKET_PATH))
  end

  -- Create or attach to tmux session
  local tmux_cmd
  if is_new_session then
    -- Create new session with the AI agent command and hide status bar
    tmux_cmd = string.format(
      "tmux new-session -s %s -c %s 'tmux set-option -t %s status off; %s%s'",
      vim.fn.shellescape(session_name),
      vim.fn.shellescape(cwd),
      vim.fn.shellescape(session_name),
      env_str,
      agent_config.cmd
    )
  else
    -- Session exists, attach to it
    tmux_cmd = string.format("tmux attach-session -t %s", vim.fn.shellescape(session_name))
  end

  -- Spawn WezTerm pane that attaches to tmux session
  local spawn_cmd = string.format(
    "wezterm cli split-pane --pane-id %d --right --percent 50 --cwd %s -- %s",
    parent_pane_id,
    vim.fn.shellescape(cwd),
    tmux_cmd
  )

  local result = vim.fn.system(spawn_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to spawn pane: " .. vim.trim(result), vim.log.levels.ERROR)
    return
  end

  local pane_id = tonumber(vim.trim(result))
  if not pane_id then
    vim.notify("Failed to parse pane ID from output: " .. vim.trim(result), vim.log.levels.ERROR)
    return
  end

  -- Wait for pane to actually exist before using it
  if not wait_for_pane(pane_id, 5) then
    vim.notify(
      string.format("Pane %d created but not accessible after spawn", pane_id),
      vim.log.levels.ERROR
    )
    return
  end

  terminals[termname] = {
    pane_id = pane_id,
    session_name = session_name,
    cmd = agent_config.cmd,
    cwd = cwd,
  }
  active_terminal = termname

  -- Set tab title only after pane confirmed to exist
  if agent then
    set_tab_title(pane_id, string.format("%s %s", agent.icon, agent.label))
  end
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

  if not activate_pane(term_data.pane_id) then
    vim.notify(
      string.format("Failed to focus pane for %s. Reopening...", termname),
      vim.log.levels.WARN
    )
    term_data.pane_id = nil
    M.open(termname)
    return
  end

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

  -- Kill the WezTerm pane (tmux session stays alive in background)
  if kill_pane(term_data.pane_id) then
    term_data.pane_id = nil
  end

  -- Focus back to neovim
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

  -- Check if tmux session exists
  if not tmux_session_exists(term_data.session_name) then
    vim.notify(string.format("Session no longer exists for %s. Reopening...", termname), vim.log.levels.WARN)
    terminals[termname] = nil
    M.open(termname)
    return
  end

  -- If already visible, just focus
  if is_visible(termname) then
    M.focus(termname)
    return
  end

  -- Spawn new WezTerm pane and attach to existing tmux session
  local tmux_cmd = string.format("tmux attach-session -t %s", vim.fn.shellescape(term_data.session_name))

  local spawn_cmd = string.format(
    "wezterm cli split-pane --pane-id %d --right --percent 50 --cwd %s -- %s",
    parent_pane_id,
    vim.fn.shellescape(term_data.cwd),
    tmux_cmd
  )

  local result = vim.fn.system(spawn_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to spawn pane: " .. vim.trim(result), vim.log.levels.ERROR)
    return
  end

  local pane_id = tonumber(vim.trim(result))
  if not pane_id then
    vim.notify("Failed to parse pane ID: " .. vim.trim(result), vim.log.levels.ERROR)
    return
  end

  -- Wait for pane to actually exist
  if not wait_for_pane(pane_id, 5) then
    vim.notify(
      string.format("Pane %d created but not accessible after respawn", pane_id),
      vim.log.levels.ERROR
    )
    return
  end

  term_data.pane_id = pane_id
  active_terminal = termname

  -- Set tab title
  local agents = require("sysinit.plugins.intellicode.agents")
  local agent = agents.get_by_name(termname)
  if agent then
    set_tab_title(pane_id, string.format("%s %s", agent.icon, agent.label))
  end
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

  -- Check if session exists
  if not tmux_session_exists(term_data.session_name) then
    vim.notify(string.format("Session no longer exists for %s", termname), vim.log.levels.ERROR)
    return
  end

  -- Send to tmux session directly (works even if not visible)
  local send_cmd =
    string.format("tmux send-keys -t %s %s", vim.fn.shellescape(term_data.session_name), vim.fn.shellescape(text))
  local result = vim.fn.system(send_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify(string.format("Failed to send text to %s: %s", termname, vim.trim(result)), vim.log.levels.ERROR)
    return
  end

  if opts.submit then
    local submit_cmd = string.format("tmux send-keys -t %s Enter", vim.fn.shellescape(term_data.session_name))
    result = vim.fn.system(submit_cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify(
        string.format("Failed to submit in %s: %s", termname, vim.trim(result)),
        vim.log.levels.ERROR
      )
    end
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

  -- Kill WezTerm pane if exists
  if term_data.pane_id then
    kill_pane(term_data.pane_id)
  end

  -- Kill tmux session
  if tmux_session_exists(term_data.session_name) then
    local result = vim.fn.system(string.format("tmux kill-session -t %s", vim.fn.shellescape(term_data.session_name)))
    if vim.v.shell_error ~= 0 then
      vim.notify(
        string.format("Failed to kill session %s: %s", term_data.session_name, vim.trim(result)),
        vim.log.levels.WARN
      )
    end
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

-- Improved: Poll for pane to be ready instead of arbitrary delay
function M.ensure_active_and_send(text)
  if not active_terminal then
    vim.notify("No active AI terminal. Select one with <leader>jj", vim.log.levels.WARN)
    return
  end

  local term_info = M.get_info(active_terminal)
  if not term_info or not M.exists(active_terminal) then
    M.open(active_terminal)
    M.focus(active_terminal)

    -- Wait for pane to be ready, then send
    vim.fn.system("sleep 0.2")
    if M.exists(active_terminal) then
      M.send(active_terminal, text, { submit = true })
    end
  else
    if not is_visible(active_terminal) then
      M.show(active_terminal)
      -- Give pane a moment to be ready
      vim.fn.system("sleep 0.1")
    else
      M.focus(active_terminal)
    end
    M.send(active_terminal, text, { submit = true })
  end
end

return M
