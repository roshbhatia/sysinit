local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

local M = {}

local function get_transparency_config()
  return theme_config.transparency.enable and {
    transparent_background = true,
    show_end_of_buffer = false,
  } or {
    transparent_background = false,
    show_end_of_buffer = true,
  }
end

M.get_theme_config = get_transparency_config
M.theme_config = theme_config

local theme_modules = {
  catppuccin = require("sysinit.themes.catppuccin"),
  gruvbox = require("sysinit.themes.gruvbox"),
  kanagawa = require("sysinit.themes.kanagawa"),
  ["rose-pine"] = require("sysinit.themes.rose_pine"),
  solarized = require("sysinit.themes.solarized"),
  nord = require("sysinit.themes.nord"),
}

local function setup_theme()
  local plugin_config = theme_config.plugins[theme_config.colorscheme][theme_config.variant]
  local theme_module = theme_modules[theme_config.colorscheme]

  if theme_module and theme_module.setup then
    theme_module.setup(get_transparency_config())
  end

  vim.cmd("colorscheme " .. plugin_config.colorscheme)
end

M.plugins = {
  {
    theme_config.plugins[theme_config.colorscheme][theme_config.variant].plugin,
    name = theme_config.plugins[theme_config.colorscheme][theme_config.variant].name,
    lazy = false,
    priority = 1000,
    config = setup_theme,
  },
}

return M
