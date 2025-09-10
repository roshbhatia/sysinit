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
        left = wezterm.nerdfonts.ple_right_half_circle_thick,
        right = wezterm.nerdfonts.ple_left_half_circle_thick,
      },
    },
    sections = {
      tabline_a = {
        {
          "mode",
          icon = "",
          padding = { left = 1, right = 1 },
        },
      },
      tabline_b = {
        {
          "hostname",
          icon = wezterm.nerdfonts.cod_server,
          padding = { left = 1, right = 1 },
        },
      },
      tabline_c = {
        " ",
      },
      tab_active = {
        {
          "index",
          icon = wezterm.nerdfonts.cod_circle_filled,
          padding = { left = 0, right = 0 },
        },
        {
          "process",
          padding = { left = 1, right = 1 },
        },
        function(tab)
          local close_btn = wezterm.nerdfonts.fa_times_circle
          return {
            { Foreground = { Color = colors.ansi[1] } },
            { Background = { Color = colors.tab_bar.active_tab.bg_color } },
            { Text = " " .. close_btn },
          }
        end,
      },
      tab_inactive = {
        {
          "index",
          icon = wezterm.nerdfonts.cod_circle_outline,
          padding = { left = 0, right = 0 },
        },
        {
          "process",
          padding = { left = 1, right = 1 },
        },
        function(tab)
          local close_btn = wezterm.nerdfonts.fa_times_circle_o
          return {
            { Foreground = { Color = colors.tab_bar.inactive_tab.fg_color } },
            { Background = { Color = colors.tab_bar.inactive_tab.bg_color } },
            { Text = " " .. close_btn },
          }
        end,
      },
      tabline_x = {
        " ",
      },
      tabline_y = {},
      tabline_z = {
        " 󱄅 ",
      },
    },
    extensions = {},
  })

  tabline.apply_to_config(config)
end

return M
