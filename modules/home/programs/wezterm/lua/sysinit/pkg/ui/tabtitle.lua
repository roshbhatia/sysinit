local wezterm = require("wezterm")
local ui_badges = require("sysinit.pkg.ui.badges")
local ui_format = require("sysinit.pkg.ui.format")

local nf = wezterm.nerdfonts or {}

local M = {}

local SHELLS = { zsh = true, bash = true, fish = true, sh = true, ["-zsh"] = true }

function M.format(tab, cfg, ctx)
  local pane = tab.active_pane
  local explicit = ui_format.normalize_proc(tab.tab_title or "")
  local osc = ui_format.normalize_proc(pane and pane.title or "")
  local proc = pane and pane.foreground_process_name
  if proc then
    proc = ui_format.normalize_proc(proc:match("([^/]+)$") or proc)
  end

  if explicit ~= "" and not explicit:match("^%d+$") then
    return explicit
  end

  local dir
  local cwd_uri = pane and pane.current_working_dir
  if cwd_uri then
    local cwd = cwd_uri.file_path or tostring(cwd_uri)
    if ctx.home ~= "" and cwd == ctx.home then
      dir = "~"
    else
      dir = cwd:match("([^/]+)/?$") or cwd
    end
  end

  local label
  if osc and osc ~= "" and not osc:match("^%d+$") and not SHELLS[osc:lower()] and not ui_format.is_passthrough(osc) then
    label = osc
  end
  if ui_format.is_passthrough(proc) then
    proc = nil
  end
  label = label or dir or proc or "shell"

  if not (ctx.sigil_ok and ctx.ribbon_ok) then
    return label
  end

  local r = ctx.ribbon.new("tab")

  pcall(function()
    local uv = pane and pane.user_vars
    local raw = uv and uv.agent_state
    if not raw or raw == "" then
      return
    end
    local s = raw:match("^([^|]*)|")
    local icon = s and s ~= "idle" and ui_format.state_icons[s]
    if icon then
      r:append(nil, nil, icon .. " ")
    end
  end)

  if pane and pane.is_zoomed then
    r:append(nil, nil, nf.md_dock_window and (nf.md_dock_window .. " ") or "⊞ ")
  end

  if proc then
    local icon_items = ctx.sigil.items(proc, { padding = "right", fallback = false, reset = true })
    if icon_items and #icon_items > 0 then
      r:append_items(icon_items)
    end
  end

  r:append(nil, nil, label)

  if pane and pane.pane_id then
    local pid = pane.pane_id
    local bc = ui_badges.color(pid, cfg and cfg.colors or {})
    if bc then
      r:append(nil, "#3b4261", "  ")
      r:append(nil, bc, ui_badges.name(pid))
    end
  end

  return r:items()
end

return M
