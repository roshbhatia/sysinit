local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

local M = {}

function M.setup(config)
  tabline.setup({
    options = {
      theme = config.colors,
      section_separators = {
        left = wezterm.nerdfonts.pl_left_hard_divider,
        right = wezterm.nerdfonts.pl_right_hard_divider,
      },
      component_separators = {
        left = wezterm.nerdfonts.pl_left_soft_divider,
        right = wezterm.nerdfonts.pl_right_soft_divider,
      },
      tab_separators = "",
    },
    sections = {
      tabline_a = {
        "mode",
      },
      tabline_b = {
        "hostname",
      },
      tabline_c = {
        " ",
      },
      tab_active = {
        "index",
        {
          "process",
          padding = {
            left = 1,
            right = 2,
          },
        },
      },
      tab_inactive = {
        "index",
        {
          "process",
          padding = {
            left = 1,
            right = 2,
          },
        },
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
