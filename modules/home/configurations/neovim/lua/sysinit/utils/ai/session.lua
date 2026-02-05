-- Session management facade with auto-detection of terminal backend
local M = {}

local backend = nil -- Backend module (wezterm or native)
local config = {}
local terminals = {}
local active_terminal = nil
local augroup = nil

-- Detect which backend to use based on environment
-- @return string: "wezterm" or "native"
local function detect_backend()
  -- Priority 1: SSH → force native (even if WEZTERM_PANE exists)
  if vim.env.SSH_CONNECTION then
    return "native"
  end

  -- Priority 2: WezTerm available → use wezterm
  if vim.env.WEZTERM_PANE then
    local pane_id = tonumber(vim.env.WEZTERM_PANE)
    if pane_id then
      -- Verify wezterm CLI actually works
      vim.fn.system("wezterm cli list 2>/dev/null")
      if vim.v.shell_error == 0 then
        return "wezterm"
      end
    end
  end

  -- Priority 3: Fallback to native
  return "native"
end

-- Setup the session manager with backend detection
-- @param opts table: Configuration options
function M.setup(opts)
  config = opts or {}
  config.terminals = config.terminals or {}
  config.env = config.env or {}

  -- Detect and load backend
  local backend_type = detect_backend()
  if backend_type == "wezterm" then
    backend = require("sysinit.utils.ai.backends.wezterm")
  else
    backend = require("sysinit.utils.ai.backends.native")
  end

  backend.setup(config)

  -- Setup autocmds (cleanup tracking fields for both backends)
  if not augroup then
    augroup = vim.api.nvim_create_augroup("AIManager", { clear = true })

    vim.api.nvim_create_autocmd("CursorHold", {
      group = augroup,
      callback = function()
        for _, term_data in pairs(terminals) do
          if not backend.is_visible(term_data) then
            -- Clear backend-specific visibility tracking
            term_data.pane_id = nil
            term_data.win = nil
          end
        end
      end,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = augroup,
      callback = function()
        backend.cleanup_all(terminals)
      end,
    })
  end
end

-- Open a terminal (creates or focuses existing)
-- @param termname string: Terminal name
function M.open(termname)
  local agent_config = config.terminals[termname]
  if not agent_config then
    return
  end

  if terminals[termname] and backend.is_visible(terminals[termname]) then
    M.focus(termname)
    return
  end

  if not backend then
    vim.notify("Backend not initialized", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local term_data = backend.open(termname, agent_config, cwd)

  if term_data then
    terminals[termname] = term_data
    active_terminal = termname
  end
end

-- Toggle terminal visibility
-- @param termname string: Terminal name
function M.toggle(termname)
  local term_data = terminals[termname]

  if term_data and backend and backend.is_visible(term_data) then
    M.focus(termname)
  else
    M.open(termname)
  end
end

-- Focus a terminal
-- @param termname string: Terminal name
function M.focus(termname)
  local term_data = terminals[termname]

  if not term_data or not backend then
    return
  end

  if not backend.is_visible(term_data) then
    vim.notify(string.format("Terminal no longer visible for %s. Reopening...", termname), vim.log.levels.WARN)
    term_data.pane_id = nil
    term_data.win = nil
    M.open(termname)
    return
  end

  if not backend.focus(term_data) then
    vim.notify(string.format("Failed to focus %s. Reopening...", termname), vim.log.levels.WARN)
    term_data.pane_id = nil
    term_data.win = nil
    M.open(termname)
    return
  end

  active_terminal = termname
end

-- Hide a terminal (closes visible UI, no persistence)
-- @param termname string: Terminal name
function M.hide(termname)
  local term_data = terminals[termname]

  if not term_data or not backend then
    return
  end

  backend.hide(term_data)
end

-- Show a hidden terminal (not supported without persistence)
-- @param termname string: Terminal name
function M.show(termname)
  local term_data = terminals[termname]

  if not term_data or not backend then
    vim.notify(string.format("Terminal not found: %s", termname), vim.log.levels.WARN)
    return
  end

  -- Without persistence, just reopen the terminal
  terminals[termname] = nil
  M.open(termname)
end

-- Check if terminal is visible
-- @param termname string: Terminal name
-- @return boolean: True if visible
function M.is_visible(termname)
  local term_data = terminals[termname]
  if not term_data or not backend then
    return false
  end
  return backend.is_visible(term_data)
end

-- Send text to a terminal
-- @param termname string: Terminal name
-- @param text string: Text to send
-- @param opts table: Options with optional 'submit' field
function M.send(termname, text, opts)
  opts = opts or {}
  local term_data = terminals[termname]

  if not term_data then
    return
  end

  -- For WezTerm backend, use wezterm CLI to send text
  if term_data.pane_id then
    local send_cmd =
      string.format("wezterm cli send-text --pane-id %d --no-paste %s", term_data.pane_id, vim.fn.shellescape(text))
    vim.fn.system(send_cmd)

    if opts.submit then
      vim.fn.system(string.format("wezterm cli send-text --pane-id %d --no-paste '\n'", term_data.pane_id))
    end
  -- For native backend, use Snacks terminal functionality
  elseif term_data.term then
    term_data.term:send(text)
    if opts.submit then
      term_data.term:send("\n")
    end
  end
end

-- Get terminal information
-- @param termname string: Terminal name
-- @return table|nil: Terminal info or nil if not found
function M.get_info(termname)
  local term_data = terminals[termname]

  if not term_data or not backend then
    return nil
  end

  return {
    name = termname,
    visible = backend.is_visible(term_data),
    pane_id = term_data.pane_id,
    cmd = term_data.cmd,
    cwd = term_data.cwd,
    win = term_data.win,
    buf = term_data.buf,
  }
end

-- Get all terminal information
-- @return table: Map of terminal name to info
function M.get_all()
  local result = {}
  for name, _ in pairs(terminals) do
    result[name] = M.get_info(name)
  end
  return result
end

-- Check if terminal exists (is tracked and visible)
-- @param termname string: Terminal name
-- @return boolean: True if exists
function M.exists(termname)
  local term_data = terminals[termname]
  if not term_data or not backend then
    return false
  end
  return backend.is_visible(term_data)
end

-- Close a terminal (kill UI)
-- @param termname string: Terminal name
function M.close(termname)
  local term_data = terminals[termname]

  if not term_data or not backend then
    return
  end

  backend.kill(term_data)

  terminals[termname] = nil
  if active_terminal == termname then
    active_terminal = nil
  end
end

-- Cleanup terminal from tracking (doesn't kill session)
-- @param termname string: Terminal name
function M.cleanup_terminal(termname)
  terminals[termname] = nil
  if active_terminal == termname then
    active_terminal = nil
  end
end

-- Get the active terminal name
-- @return string|nil: Active terminal name or nil
function M.get_active()
  return active_terminal
end

-- Set the active terminal
-- @param termname string: Terminal name
function M.set_active(termname)
  if terminals[termname] then
    active_terminal = termname
  end
end

-- Activate a terminal (open if needed, show if hidden, focus if visible)
-- @param termname string: Terminal name
function M.activate(termname)
  local term_data = terminals[termname]

  if not term_data then
    M.open(termname)
  else
    if backend and backend.is_visible(term_data) then
      M.focus(termname)
    else
      M.show(termname)
    end
    active_terminal = termname
  end
end

-- Send text to the active terminal
-- @param text string: Text to send
-- @param opts table: Options with optional 'submit' field
function M.send_to_active(text, opts)
  if not active_terminal then
    vim.notify("No active AI terminal", vim.log.levels.WARN)
    return
  end
  M.send(active_terminal, text, opts)
end

-- Ensure active terminal exists and send text
-- @param text string: Text to send
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
    if backend and not backend.is_visible(terminals[active_terminal]) then
      M.show(active_terminal)
      vim.fn.system("sleep 0.1")
    else
      M.focus(active_terminal)
    end
    M.send(active_terminal, text, { submit = true })
  end
end

return M
