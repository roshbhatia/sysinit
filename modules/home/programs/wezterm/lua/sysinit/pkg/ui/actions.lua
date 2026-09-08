local wezterm = require("wezterm")
local ui_sessions = require("sysinit.pkg.ui.sessions")
local ui_tether = require("sysinit.pkg.ui.tether")
local utils = require("sysinit.pkg.utils")

local M = {}
local refresh_handler

function M.set_refresh_handler(handler)
  refresh_handler = handler
end

local function refresh(window)
  if not refresh_handler then
    return
  end
  wezterm.time.call_after(0.05, function()
    pcall(refresh_handler, window)
  end)
end

-- `nu -e` runs the jump and then stays interactive, so no exec is needed. The
-- name is double-quoted because a nushell single-quoted string has no escape at
-- all, while a double-quoted one takes \" and \\.
local function seshy_spawn_args(name)
  local args = utils.get_nushell_args()
  local quoted = '"' .. name:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
  args[#args + 1] = "-e"
  args[#args + 1] = string.format("s %s", quoted)
  return args
end

-- The far side of every remote attach. zmx is the host's own multiplexer, so
-- the same argv runs at the WezTerm ssh domain or behind a mosh or ssh hop.
-- tether wraps it; it never composes it.
local function remote_inner_args(session)
  return { "zmx", "attach", session }
end

-- Asks tether which hop carries the attach. This is the one synchronous child
-- allowed on the GUI thread: `tether plan` reads its own host record and the
-- local tool table and never opens the network, so it answers in milliseconds.
-- A plan that cannot be used is logged with tether's reasons and the attach
-- falls back to the ssh domain, never to a silent no-op.
local function tether_spawn(opts, session)
  local inner = remote_inner_args(session)
  local args = ui_tether.plan_args(utils.get_nix_binary("tether"), opts.host, session, opts.domain, inner)
  local ran, success, stdout, stderr = pcall(wezterm.run_child_process, args)
  if not ran then
    success, stdout, stderr = false, "", tostring(success)
  end
  local parsed, plan = pcall(wezterm.json_parse, stdout or "")
  local spawn, err = ui_tether.spawn_for(parsed and plan or nil, opts.cwd)
  if spawn then
    return spawn
  end
  local detail = ""
  if not success and type(stderr) == "string" and stderr:match("%S") then
    detail = " (" .. stderr:gsub("%s+$", "") .. ")"
  end
  wezterm.log_error(
    string.format("tether plan --host %s: %s%s; attaching over %s", opts.host, err, detail, opts.domain)
  )
  return { domain = { DomainName = opts.domain }, cwd = opts.cwd, args = inner }
end

function M.gui_window_for_workspace(workspace)
  if not workspace or workspace == "" then
    return nil
  end
  local windows = {}
  pcall(function()
    windows = wezterm.mux.all_windows()
  end)
  for _, w in ipairs(windows) do
    local ok_ws, ws = pcall(function()
      return w:get_workspace()
    end)
    if ok_ws and ws == workspace then
      local ok_gui, gui = pcall(function()
        return w:gui_window()
      end)
      if ok_gui and gui then
        return gui
      end
    end
  end
  return nil
end

---@param opts table|string|nil A spawn cwd, or { cwd, domain, session, host }
function M.switch_to_workspace(win, pane, name, opts)
  if not name or name == "" then
    return
  end
  local ok_active, active = pcall(function()
    return win:active_workspace()
  end)
  if ok_active and active == name then
    return
  end
  local gui = M.gui_window_for_workspace(name)
  if gui then
    pcall(function()
      gui:focus()
    end)
    refresh(gui)
    return
  end
  if type(opts) == "string" then
    opts = { cwd = opts }
  end
  local act
  if type(opts) == "table" and opts.host and opts.domain then
    local spawn = tether_spawn(opts, opts.session or name)
    act = wezterm.action.SwitchToWorkspace({ name = name, spawn = spawn })
  elseif type(opts) == "table" and (opts.cwd or opts.domain) then
    local spawn = {
      cwd = opts.cwd,
      args = seshy_spawn_args(opts.session or name),
    }
    if opts.domain and opts.domain ~= "" then
      spawn.domain = { DomainName = opts.domain }
    end
    act = wezterm.action.SwitchToWorkspace({ name = name, spawn = spawn })
  else
    act = wezterm.action.SwitchToWorkspace({ name = name })
  end
  win:perform_action(act, pane)
  refresh(win)
end

-- The slot is what the session chips are numbered with, so a slot jump and a
-- chip read the same order. A dormant session spawns on the way in.
function M.activate_slot(win, pane, slot)
  local target
  for name, s in pairs(ui_sessions.slots()) do
    if s == slot then
      target = name
      break
    end
  end
  if not target then
    return
  end
  local live = false
  pcall(function()
    for _, w in ipairs(wezterm.mux.all_windows()) do
      if w:get_workspace() == target then
        live = true
      end
    end
  end)
  local spawn = nil
  if not live and target ~= ui_sessions.DEFAULT_WORKSPACE then
    spawn = ui_sessions.remote_spawn(target) or { cwd = ui_sessions.seshy_dir .. "/" .. target }
  end
  M.switch_to_workspace(win, pane, target, spawn)
end

-- Stepping by slot rather than by workspace name walks the same order the
-- session chips are drawn in, and wraps at both ends.
function M.step_session(win, pane, step)
  local taken = {}
  for _, slot in pairs(ui_sessions.slots()) do
    taken[#taken + 1] = slot
  end
  table.sort(taken)
  if #taken < 2 then
    return
  end

  local here = ui_sessions.slots()[win:active_workspace()]
  local at = 1
  for index, slot in ipairs(taken) do
    if slot == here then
      at = index
      break
    end
  end

  M.activate_slot(win, pane, taken[(at - 1 + step) % #taken + 1])
end

function M.activate_agent_pane(win, gui_pane, rec)
  if not rec or not rec.pane_id then
    return
  end
  local mux_win
  pcall(function()
    local mp = wezterm.mux.get_pane(rec.pane_id)
    if not mp then
      return
    end
    local tab = mp:tab()
    if tab then
      tab:activate()
      mux_win = tab:window()
    end
    mp:activate()
  end)
  local gui
  if mux_win then
    pcall(function()
      gui = mux_win:gui_window()
    end)
  end
  if gui then
    pcall(function()
      gui:focus()
    end)
    return
  end
  M.switch_to_workspace(win, gui_pane, rec.workspace)
end
return M
