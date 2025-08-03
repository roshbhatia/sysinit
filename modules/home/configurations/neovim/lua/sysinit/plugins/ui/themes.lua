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

local function get_kanagawa_config()
  local transparency = get_transparency_config()

  return {
    compile = false,
    undercurl = true,
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = transparency.transparent_background,
    dimInactive = false,
    terminalColors = true,
    colors = {
      palette = {},
      theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
    },
    overrides = function(colors)
      return transparency.transparent_background
          and {
            Normal = { bg = "none" },
            NormalNC = { bg = "none" },
            NormalFloat = { bg = "none" },
            FloatBorder = { bg = "none" },
            FloatTitle = { bg = "none" },
            Pmenu = { bg = "none" },
            TelescopeNormal = { bg = "none" },
            TelescopeBorder = { bg = "none" },
            SignColumn = { bg = "none" },
            CursorLine = { bg = "none" },
            StatusLine = { bg = "none" },
            StatusLineNC = { bg = "none" },
            WinSeparator = { bg = "none" },
            NeoTreeNormal = { bg = "none" },
            NeoTreeNormalNC = { bg = "none" },
            NeoTreeWinSeparator = { bg = "none" },
            WinBar = { bg = "none" },
            WinBarNC = { bg = "none" },
          }
        or {}
    end,
    theme = theme_config.variant,
  }
end

local function get_plugin_config()
  local colorscheme_config = theme_config.plugins[theme_config.colorscheme]
  if not colorscheme_config then
    error("No plugin configuration found for colorscheme: " .. theme_config.colorscheme)
  end

  -- If variant-specific config exists, use it; otherwise use the base config
  local plugin_config = colorscheme_config[theme_config.variant] or colorscheme_config

  return plugin_config
end

local function setup_theme()
  local plugin_config = get_plugin_config()

  if theme_config.colorscheme == "kanagawa" then
    require("kanagawa").setup(get_kanagawa_config())
  end

  vim.cmd("colorscheme " .. plugin_config.colorscheme)
end

M.plugins = {
  {
    get_plugin_config().plugin,
    name = get_plugin_config().name,
    lazy = false,
    priority = 1000,
    config = setup_theme,
  },
}

return M
