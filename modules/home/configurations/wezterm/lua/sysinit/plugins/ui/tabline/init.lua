local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

local M = {}

function M.setup(config)
  local colors = config.colors

  tabline.setup({
    options = {
      theme = colors,
      theme_overrides = {
        normal_mode = {
          a = { fg = colors.tab_bar.active_tab.fg_color, bg = colors.ansi[5] },
          b = { fg = colors.ansi[5], bg = colors.tab_bar.inactive_tab.bg_color },
          c = { fg = colors.foreground, bg = colors.background },
        },
        copy_mode = {
          a = { fg = colors.background, bg = colors.ansi[4] },
          b = { fg = colors.ansi[4], bg = colors.tab_bar.inactive_tab.bg_color },
          c = { fg = colors.foreground, bg = colors.background },
        },
        search_mode = {
          a = { fg = colors.background, bg = colors.ansi[2] },
          b = { fg = colors.ansi[2], bg = colors.tab_bar.inactive_tab.bg_color },
          c = { fg = colors.foreground, bg = colors.background },
        },
        tab = {
          active = {
            fg = colors.tab_bar.active_tab.fg_color,
            bg = colors.tab_bar.active_tab.bg_color,
          },
          inactive = {
            fg = colors.tab_bar.inactive_tab.fg_color,
            bg = colors.tab_bar.inactive_tab.bg_color,
          },
          inactive_hover = {
            fg = colors.tab_bar.inactive_tab_hover.fg_color,
            bg = colors.tab_bar.inactive_tab_hover.bg_color,
          },
        },
      },
      section_separators = {
        left = wezterm.nerdfonts.ple_right_half_circle_thick,
        right = wezterm.nerdfonts.ple_left_half_circle_thick,
      },
      component_separators = {
        left = wezterm.nerdfonts.ple_right_half_circle_thin,
        right = wezterm.nerdfonts.ple_left_half_circle_thin,
      },
      tab_separators = {
        left = " ",
        right = " ",
      },
    },
    sections = {
      tabline_a = {
        {
          "mode",
          icon = "  ",
          padding = { left = 1, right = 1 },
        },
      },
      tabline_b = {
        "domain",
      },
      tabline_x = {},
      tabline_y = {},
      tabline_z = {},
      tab_active = {
        {
          "index",
          padding = { left = 1 },
        },
        ":",
        {
          "parent",
          padding = { left = 1, right = 0 },
        },
        "/",
        {
          "cwd",
          padding = { left = 0, right = 1 },
        },
        { "zoomed", padding = { left = 1, right = 1 } },
      },
      tab_inactive = {
        {
          "index",
          padding = { left = 1 },
        },
        ":",
        {
          "parent",
          padding = { left = 1, right = 0 },
        },
        "/",
        {
          "cwd",
          padding = { left = 0, right = 1 },
        },
      },
    },
    extensions = {},
  })

  tabline.apply_to_config(config)

  -- Mouse bindings for tab management
  config.mouse_bindings = config.mouse_bindings or {}
  table.insert(config.mouse_bindings, {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action.CloseCurrentTab({ confirm = false }),
  })
end

return M
