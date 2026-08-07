local wezterm = require("wezterm")

local M = {}

function M.setup(config)
  -- Set by nvim's smart-splits config when the cursor is already at the edge of
  -- its own splits and the move has to continue into a wezterm pane. nvim asks
  -- rather than moving itself, because over ssh it can reach neither `wezterm
  -- cli` nor this process any other way. The payload is "<direction>:<seq>";
  -- the counter only exists to make the value differ so this event fires again.
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
