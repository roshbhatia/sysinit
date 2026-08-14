local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

-- A remote host has its own nix profile, so its zsh is never at the local path.
local function seshy_spawn_args(name, shell)
  local zsh = (shell and shell ~= "") and shell or utils.get_nix_binary("zsh")
  local quoted = "'" .. name:gsub("'", "'\\''") .. "'"
  return { zsh, "-i", "-c", string.format("s %s; exec %s -i", quoted, zsh) }
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

---@param opts table|string|nil A spawn cwd, or { cwd, domain, shell, session }
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
    return
  end
  if type(opts) == "string" then
    opts = { cwd = opts }
  end
  local act
  if type(opts) == "table" and (opts.cwd or opts.domain) then
    local spawn = {
      cwd = opts.cwd,
      args = seshy_spawn_args(opts.session or name, opts.shell),
    }
    if opts.domain and opts.domain ~= "" then
      spawn.domain = { DomainName = opts.domain }
    end
    act = wezterm.action.SwitchToWorkspace({ name = name, spawn = spawn })
  else
    act = wezterm.action.SwitchToWorkspace({ name = name })
  end
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
