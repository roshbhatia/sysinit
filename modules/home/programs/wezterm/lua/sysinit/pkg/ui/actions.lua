local wezterm = require("wezterm")
local ui_sessions = require("sysinit.pkg.ui.sessions")
local ui_spawn = require("sysinit.pkg.ui.spawn")

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

-- Switches to a workspace. A live one is focused. A dormant one spawns from
-- its catalog row's plan, or, with no row, WezTerm's default program. A row
-- that yields no spawn is logged with the row's reason and nothing else
-- happens: there is no guessed domain or directory to fall back to.
---@param row table|nil the catalog row to spawn from when the workspace is not live
function M.switch_to_workspace(win, pane, name, row)
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
  local act
  if row ~= nil then
    local spawn, err = ui_spawn.spawn_for(row, ui_spawn.resolver(ui_sessions.roster_opener))
    if not spawn then
      wezterm.log_error(string.format("session %s: %s", name, tostring(err)))
      return
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
  local row = nil
  if target ~= ui_sessions.DEFAULT_WORKSPACE then
    row = ui_sessions.row_for(target)
  end
  M.switch_to_workspace(win, pane, target, row)
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

-- Opens a catalog row. A row a live pane already shows is activated, never
-- spawned again; anything else goes through switch_to_workspace.
function M.open_row(win, pane, row)
  if type(row) ~= "table" then
    return
  end
  local pane_id = tonumber(row.pane)
  if pane_id then
    M.activate_agent_pane(win, pane, { pane_id = pane_id, workspace = row.workspace })
    return
  end
  M.switch_to_workspace(win, pane, row.workspace, row)
end

return M
