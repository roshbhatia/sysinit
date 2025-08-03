local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
local M = {}

function M.setup(config)
  tabline.setup({
    options = {
      theme = config.colors,
      section_separators = "",
      component_separators = "",
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
      tabline_y = {
        "domain",
      },
      tabline_z = {
        " 󱄅 ",
      },
    },
    extensions = {},
  })

  tabline.apply_to_config(config)
end

return M

