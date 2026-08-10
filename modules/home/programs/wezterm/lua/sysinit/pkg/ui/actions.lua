local wezterm = require("wezterm")

local M = {}

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

function M.switch_to_workspace(win, pane, name, spawn_cwd)
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
    return
  end
  local act = spawn_cwd and wezterm.action.SwitchToWorkspace({ name = name, spawn = { cwd = spawn_cwd } })
    or wezterm.action.SwitchToWorkspace({ name = name })
  win:perform_action(act, pane)
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
