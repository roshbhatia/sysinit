local wezterm = require("wezterm")

local M = {}

function M.setup(config)
  local NAV_DIRECTIONS = {
    left = "Left",
    right = "Right",
    up = "Up",
    down = "Down",
  }

  wezterm.on("user-var-changed", function(window, pane, name, value)
    if name == "wez_copy" then
      window:copy_to_clipboard(value, "Clipboard")
    elseif name == "wez_not" then
      window:toast_notification("wezterm", value, nil, 4000)
    elseif name == "SYSINIT_NAV" then
      local dir = NAV_DIRECTIONS[tostring(value):match("^(%a+):") or ""]
      if dir then
        window:perform_action(wezterm.action.ActivatePaneDirection(dir), pane)
      end
    end
  end)

  config.enable_scroll_bar = true
  wezterm.on("update-status", function(window, pane)
    local overrides = window:get_config_overrides() or {}
    local dimensions = pane:get_dimensions()
    overrides.enable_scroll_bar = dimensions.scrollback_rows > dimensions.viewport_rows
      and not pane:is_alt_screen_active()
    window:set_config_overrides(overrides)
  end)
end

return M
