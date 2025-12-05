-- modules/home/configurations/neovim/lua/sysinit/plugins/intellicode/ai/ai_manager.lua
-- AI terminal manager using tmux sessions for persistence + WezTerm panes for UI

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

-- Get pane information from WezTerm
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

  local result = vim.fn.system("tmux list-sessions -F '#{session_name}' 2>/dev/null")
  if vim.v.shell_error ~= 0 then
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
  vim.fn.system(string.format("tmux has-session -t %s 2>/dev/null", vim.fn.shellescape(session_name)))
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

function M.setup(opts)
  config = opts or {}
  config.terminals = config.terminals or {}
  config.env = config.env or {}

  parent_pane_id = get_current_pane_id()
  if not parent_pane_id then
    vim.notify(
      "Warning: Unable to determine WezTerm pane ID. AI terminals may not work correctly.",
      vim.log.levels.WARN
    )
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
            vim.fn.system(string.format("wezterm cli kill-pane --pane-id %d 2>/dev/null", term_data.pane_id))
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
    "wezterm cli split-pane --pane-id %d --right --percent 50 --cwd %s -- %s 2>/dev/null",
    parent_pane_id,
    vim.fn.shellescape(cwd),
    tmux_cmd
  )

  local result = vim.fn.system(spawn_cmd)

  if vim.v.shell_error == 0 then
    local pane_id = nil
    for line in vim.gsplit(vim.trim(result), "\n") do
      local id = tonumber(line)
      if id then
        pane_id = id
        break
      end
    end

    if pane_id then
      terminals[termname] = {
        pane_id = pane_id,
        session_name = session_name,
        cmd = agent_config.cmd,
        cwd = cwd,
      }
      active_terminal = termname

      if agent then
        vim.defer_fn(function()
          vim.fn.system(
            string.format(
              "wezterm cli set-tab-title --pane-id %d %s 2>/dev/null",
              pane_id,
              vim.fn.shellescape(string.format("%s %s", agent.icon, agent.label))
            )
          )
        end, 100)
      end
    else
      vim.notify("Failed to parse pane ID from output: " .. result, vim.log.levels.ERROR)
    end
  else
    vim.notify("Failed to spawn pane: " .. result, vim.log.levels.ERROR)
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

  vim.fn.system(string.format("wezterm cli activate-pane --pane-id %d 2>/dev/null", term_data.pane_id))
  active_terminal = termname
end

function M.hide(termname)
  local term_data = terminals[termname]

  if not term_data or not term_data.pane_id then
    return
  end

  if not pane_exists(term_data.pane_id) then
    return
  end

  -- Kill the WezTerm pane (tmux session stays alive in background)
  vim.fn.system(string.format("wezterm cli kill-pane --pane-id %d 2>/dev/null", term_data.pane_id))
  term_data.pane_id = nil

  -- Focus back to neovim
  if parent_pane_id then
    vim.fn.system(string.format("wezterm cli activate-pane --pane-id %d 2>/dev/null", parent_pane_id))
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
    "wezterm cli split-pane --pane-id %d --right --percent 50 --cwd %s -- %s 2>/dev/null",
    parent_pane_id,
    vim.fn.shellescape(term_data.cwd),
    tmux_cmd
  )

  local result = vim.fn.system(spawn_cmd)

  if vim.v.shell_error == 0 then
    local pane_id = tonumber(vim.trim(result))
    if pane_id then
      term_data.pane_id = pane_id
      active_terminal = termname

      local agents = require("sysinit.plugins.intellicode.agents")
      local agent = agents.get_by_name(termname)
      if agent then
        vim.defer_fn(function()
          vim.fn.system(
            string.format(
              "wezterm cli set-tab-title --pane-id %d %s 2>/dev/null",
              pane_id,
              vim.fn.shellescape(string.format("%s %s", agent.icon, agent.label))
            )
          )
        end, 100)
      end
    else
      vim.notify("Failed to parse pane ID", vim.log.levels.ERROR)
    end
  else
    vim.notify("Failed to spawn pane: " .. result, vim.log.levels.ERROR)
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

  -- Kill WezTerm pane if exists
  if term_data.pane_id then
    vim.fn.system(string.format("wezterm cli kill-pane --pane-id %d 2>/dev/null", term_data.pane_id))
  end

  -- Kill tmux session
  if tmux_session_exists(term_data.session_name) then
    vim.fn.system(string.format("tmux kill-session -t %s 2>/dev/null", vim.fn.shellescape(term_data.session_name)))
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

    vim.defer_fn(function()
      M.send(active_terminal, text, { submit = true })
    end, 300)
  else
    if not is_visible(active_terminal) then
      M.show(active_terminal)
    else
      M.focus(active_terminal)
    end
    vim.defer_fn(function()
      M.send(active_terminal, text, { submit = true })
    end, 100)
  end
end

return M
