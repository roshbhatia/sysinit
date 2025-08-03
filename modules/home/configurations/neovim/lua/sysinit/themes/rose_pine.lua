local M = {}

function M.setup(transparency)
  local config = {
    theme = "roseprime",
    transparent = transparency.transparent_background,
    term_colors = true,
    alt_bg = true,
    show_eob = false,
    favor_treesitter_hl = true,
    code_style = {
      comments = "none",
      conditionals = "none",
      functions = "bold",
      keywords = "bold",
      headings = "italic",
      operators = "none",
      keyword_return = "bold",
      strings = "italic",
      variables = "none",
    },
    highlights = transparency.transparent_background
        and {
          Normal = { bg = "none" },
          NormalNC = { bg = "none" },
          NormalFloat = { bg = "none" },
          FloatBorder = { bg = "none" },
          Pmenu = { bg = "none" },
          PmenuBorder = { bg = "none" },
          TelescopeNormal = { bg = "none" },
          TelescopeBorder = { bg = "none" },
          WhichKeyFloat = { bg = "none" },
          WhichKeyBorder = { bg = "none" },
          SignColumn = { bg = "none" },
          CursorLine = { bg = "none" },
          StatusLine = { bg = "none" },
          StatusLineNC = { bg = "none" },
          WinSeparator = { bg = "none" },
          WinBar = { bg = "none", fg = "subtle" },
          WinBarNC = { bg = "none", fg = "muted" },
          NeoTreeNormal = { bg = "none" },
          NeoTreeNormalNC = { bg = "none" },
          NeoTreeWinSeparator = { bg = "none", fg = "muted" },
          NeoTreeVertSplit = { bg = "none", fg = "muted" },
          NeoTreeEndOfBuffer = { bg = "none", fg = "none" },
          DropBarIconKindDefaultNC = { bg = "none" },
          DropBarMenuNormalFloat = { bg = "none" },
          DropBarCurrentContext = { bg = "none" },
          DropBarMenuFloatBorder = { bg = "none", fg = "muted" },
          DiagnosticVirtualTextError = { bg = "none" },
          DiagnosticVirtualTextWarn = { bg = "none" },
          DiagnosticVirtualTextInfo = { bg = "none" },
          DiagnosticVirtualTextHint = { bg = "none" },
          FloatTitle = { bg = "none" },
        }
      or {},
  }

  require("neomodern").setup(config)
end

function M.get_transparent_highlights()
  return {
    Normal = { bg = "none" },
    NormalNC = { bg = "none" },
    NormalFloat = { bg = "none" },
    FloatBorder = { bg = "none" },
    Pmenu = { bg = "none" },
    PmenuBorder = { bg = "none" },
    TelescopeNormal = { bg = "none" },
    TelescopeBorder = { bg = "none" },
    WhichKeyFloat = { bg = "none" },
    WhichKeyBorder = { bg = "none" },
    SignColumn = { bg = "none" },
    CursorLine = { bg = "none" },
    StatusLine = { bg = "none" },
    StatusLineNC = { bg = "none" },
    WinSeparator = { bg = "none" },
    WinBar = { bg = "none" },
    WinBarNC = { bg = "none" },
    NeoTreeNormal = { bg = "none" },
    NeoTreeNormalNC = { bg = "none" },
    NeoTreeWinSeparator = { bg = "none" },
    NeoTreeVertSplit = { bg = "none" },
    NeoTreeEndOfBuffer = { bg = "none" },
  }
end

return M
