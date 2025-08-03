local M = {}

function M.setup(transparency)
  local config = {
    options = {
      compile_path = vim.fn.stdpath("cache") .. "/nightfox",
      compile_file_suffix = "_compiled",
      transparent = transparency.transparent_background,
      terminal_colors = true,
      dim_inactive = false,
      module_default = true,
      styles = {
        comments = "italic",
        conditionals = "NONE",
        constants = "bold",
        functions = "bold",
        keywords = "italic",
        numbers = "bold",
        operators = "NONE",
        strings = "italic",
        types = "bold",
        variables = "NONE",
      },
      inverse = {
        match_paren = false,
        visual = false,
        search = false,
      },
      modules = {
        aerial = true,
        alpha = true,
        cmp = true,
        dap_ui = true,
        fzf = true,
        gitsigns = true,
        hop = true,
        indent_blankline = true,
        lsp_trouble = true,
        native_lsp = {
          enabled = true,
          background = true,
        },
        neotree = true,
        notify = true,
        nvimtree = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
    palettes = {},
    specs = {},
    groups = transparency.transparent_background and {
      all = {
        Normal = { bg = "NONE" },
        NormalNC = { bg = "NONE" },
        NormalFloat = { bg = "NONE" },
        FloatBorder = { bg = "NONE" },
        FloatTitle = { bg = "NONE" },
        Pmenu = { bg = "NONE" },
        PmenuBorder = { bg = "NONE" },
        TelescopeNormal = { bg = "NONE" },
        TelescopeBorder = { bg = "NONE" },
        WhichKeyFloat = { bg = "NONE" },
        WhichKeyBorder = { bg = "NONE" },
        SignColumn = { bg = "NONE" },
        CursorLine = { bg = "NONE" },
        StatusLine = { bg = "NONE" },
        StatusLineNC = { bg = "NONE" },
        WinSeparator = { bg = "NONE" },
        WinBar = { bg = "NONE" },
        WinBarNC = { bg = "NONE" },
        NeoTreeNormal = { bg = "NONE" },
        NeoTreeNormalNC = { bg = "NONE" },
        NeoTreeWinSeparator = { bg = "NONE" },
        NeoTreeVertSplit = { bg = "NONE" },
        NeoTreeEndOfBuffer = { bg = "NONE" },
      },
    } or {},
  }

  require("nightfox").setup(config)
end

function M.get_transparent_highlights()
  return {
    Normal = { bg = "NONE" },
    NormalNC = { bg = "NONE" },
    NormalFloat = { bg = "NONE" },
    FloatBorder = { bg = "NONE" },
    FloatTitle = { bg = "NONE" },
    Pmenu = { bg = "NONE" },
    PmenuBorder = { bg = "NONE" },
    TelescopeNormal = { bg = "NONE" },
    TelescopeBorder = { bg = "NONE" },
    WhichKeyFloat = { bg = "NONE" },
    WhichKeyBorder = { bg = "NONE" },
    SignColumn = { bg = "NONE" },
    CursorLine = { bg = "NONE" },
    StatusLine = { bg = "NONE" },
    StatusLineNC = { bg = "NONE" },
    WinSeparator = { bg = "NONE" },
    WinBar = { bg = "NONE" },
    WinBarNC = { bg = "NONE" },
    NeoTreeNormal = { bg = "NONE" },
    NeoTreeNormalNC = { bg = "NONE" },
    NeoTreeWinSeparator = { bg = "NONE" },
    NeoTreeVertSplit = { bg = "NONE" },
    NeoTreeEndOfBuffer = { bg = "NONE" },
  }
end

return M
