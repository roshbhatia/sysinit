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
  local scrollbar_state = {}
  wezterm.on("update-status", function(window, pane)
    local ok, scrollable = pcall(function()
      local dimensions = pane:get_dimensions()
      return dimensions.scrollback_rows > dimensions.viewport_rows and not pane:is_alt_screen_active()
    end)
    if not ok then
      -- A closed pane can remain in a queued update-status event. Returning
      -- lets later status handlers refresh the active workspace and tab line.
      return
    end

    local window_id = window:window_id()
    if scrollbar_state[window_id] == scrollable then
      return
    end

    local overrides = window:get_config_overrides() or {}
    local configured = overrides.enable_scroll_bar
    if configured == nil then
      configured = config.enable_scroll_bar
    end
    if configured == scrollable then
      scrollbar_state[window_id] = scrollable
      return
    end

    if scrollable == config.enable_scroll_bar then
      overrides.enable_scroll_bar = nil
    else
      overrides.enable_scroll_bar = scrollable
    end
    window:set_config_overrides(overrides)
    scrollbar_state[window_id] = scrollable
  end)
end

return M
