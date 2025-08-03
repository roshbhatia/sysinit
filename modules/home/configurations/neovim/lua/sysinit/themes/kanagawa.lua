local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

local M = {}

function M.setup(transparency)
  local config = {
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
            -- Integration fixes
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

  require("kanagawa").setup(config)
end

function M.get_transparent_highlights()
  return {
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
end

return M
