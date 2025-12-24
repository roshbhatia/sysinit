local wezterm = require("wezterm")
local theme = require("sysinit.plugins.ui.tabline.theme")
local tabs = require("sysinit.plugins.ui.tabline.tabs")
local status = require("sysinit.plugins.ui.tabline.status")

local M = {}

function M.setup(config, opts)
  opts = opts or {}
  opts.max_tab_width = opts.max_tab_width or 24
  opts.show_mode = opts.show_mode ~= false
  opts.show_userhost = opts.show_userhost ~= false

  config.use_fancy_tab_bar = false
  config.show_new_tab_button_in_tab_bar = false
  config.tab_bar_at_bottom = true
  config.tab_max_width = opts.max_tab_width
  config.window_decorations = "RESIZE"

  config.window_padding = config.window_padding or {}
  config.window_padding.top = 0
  config.window_padding.left = "2px"
  config.window_padding.right = "2px"
  config.window_padding.bottom = "2px"

  config.colors = config.colors or {}
  config.colors.tab_bar = config.colors.tab_bar or {}
  config.colors.tab_bar.background = theme.get_background()

  config.status_update_interval = 1000

  wezterm.on("format-tab-title", function(tab, tabs_list, panes, cfg, hover, max_width)
    return tabs.format_tab_title(tab, tabs_list, panes, cfg, hover, max_width)
  end)

  wezterm.on("update-status", function(window, pane)
    if opts.show_mode or opts.show_userhost then
      status.update_status(window, pane)
    end
  end)

  config.mouse_bindings = config.mouse_bindings or {}
  table.insert(config.mouse_bindings, {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action.CloseCurrentTab({ confirm = false }),
  })
end

return M
