local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config =
  json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local M = {}

local function get_transparent_highlights()
  if not theme_config.transparency.enable then
    return {}
  end

  return {
    Normal = { bg = "none" },
    NormalNC = { bg = "none" },
    NormalFloat = { bg = "none" },
    SignColumn = { bg = "none" },
    FoldColumn = { bg = "none" },
    LineNr = { bg = "none" },
    LineNrAbove = { bg = "none" },
    LineNrBelow = { bg = "none" },
    CursorLine = { bg = "none" },
    StatusLine = { bg = "none" },
    StatusLineNC = { bg = "none" },
    WinSeparator = { bg = "none" },
    WinBar = { bg = "none" },
    WinBarNC = { bg = "none" },
    FloatBorder = { bg = "none" },
    FloatTitle = { bg = "none" },
    Pmenu = { bg = "none" },
    PmenuBorder = { bg = "none" },
    DiagnosticSignError = { bg = "none" },
    DiagnosticSignWarn = { bg = "none" },
    DiagnosticSignInfo = { bg = "none" },
    DiagnosticSignHint = { bg = "none" },
    GitSignsAdd = { bg = "none" },
    GitSignsChange = { bg = "none" },
    GitSignsDelete = { bg = "none" },
    DiagnosticVirtualTextError = { bg = "none" },
    DiagnosticVirtualTextWarn = { bg = "none" },
    DiagnosticVirtualTextInfo = { bg = "none" },
    DiagnosticVirtualTextHint = { bg = "none" },
    TelescopeNormal = { bg = "none" },
    TelescopeBorder = { bg = "none" },
    NeoTreeNormal = { bg = "none" },
    NeoTreeNormalNC = { bg = "none" },
    NeoTreeWinSeparator = { bg = "none" },
    DropBarIconKindDefault = { bg = "none" },
    DropBarIconKindDefaultNC = { bg = "none" },
    DropBarMenuNormalFloat = { bg = "none" },
    DropBarCurrentContext = { bg = "none" },
    DropBarMenuFloatBorder = { bg = "none" },
    EdgyTitle = { bg = "none" },
    EdgyIcon = { bg = "none" },
    EdgyIconActive = { bg = "none" },
    TreesitterContext = { bg = "none" },
    TreesitterContextLineNumber = { bg = "none" },
    WhichKeyFloat = { bg = "none" },
    WhichKeyBorder = { bg = "none" },
    BlinkCmpMenu = { bg = "none" },
    BlinkCmpMenuBorder = { bg = "none" },
    BlinkCmpDoc = { bg = "none" },
    BlinkCmpDocBorder = { bg = "none" },
    BlinkCmpSignatureHelp = { bg = "none" },
    BlinkCmpSignatureHelpBorder = { bg = "none" },
  }
end

local function get_catppuccin_config()
  return {
    flavour = theme_config.variant,
    show_end_of_buffer = false,
    transparent_background = theme_config.transparency.enable,
    float = {
      transparent = theme_config.transparency.enable,
      solid = not theme_config.transparency.enable,
    },
    styles = {
      comments = { "italic" },
      conditionals = { "italic" },
      loops = { "bold" },
      functions = { "bold" },
      keywords = { "italic", "bold" },
      strings = { "italic" },
      variables = {},
      numbers = { "bold" },
      booleans = { "bold", "italic" },
      properties = { "italic" },
      types = { "bold" },
      operators = { "bold" },
    },
    color_overrides = {
      [theme_config.variant] = {
        base = "#1e1e2e",
        mantle = "#181825",
        crust = "#11111b",
        blue = "#7287c7",
        green = "#9cb380",
        yellow = "#d4c481",
        red = "#d67b7b",
        pink = "#d19bc4",
        teal = "#7fb3aa",
        lavender = "#9da3d4",
        peach = "#c7a584",
        mauve = "#b39bc7",
      },
    },
    highlight_overrides = {
      [theme_config.variant] = function(colors)
        local overrides = get_transparent_highlights()

        overrides.CursorLineNr = { fg = colors.lavender, style = { "bold" } }
        overrides.LineNr = { fg = colors.overlay1 }
        overrides.Visual = { bg = colors.surface1, style = { "bold" } }
        overrides.Search = { bg = colors.yellow, fg = colors.base, style = { "bold" } }
        overrides.IncSearch = { bg = colors.red, fg = colors.base, style = { "bold" } }
        overrides.PmenuSel = { bg = colors.surface0, fg = colors.lavender, style = { "bold" } }
        overrides.PmenuBorder = { fg = colors.lavender }
        overrides.FloatBorder = { fg = colors.lavender }
        overrides.FloatTitle = { fg = colors.pink, style = { "bold" } }
        overrides.TelescopeBorder = { fg = colors.blue }
        overrides.TelescopeSelection =
          { bg = colors.surface0, fg = colors.lavender, style = { "bold" } }
        overrides.TelescopeTitle = { fg = colors.pink, style = { "bold" } }
        overrides.WhichKeyBorder = { fg = colors.lavender }
        overrides.DiagnosticError = { fg = colors.red, style = { "bold" } }
        overrides.DiagnosticWarn = { fg = colors.yellow, style = { "bold" } }
        overrides.DiagnosticInfo = { fg = colors.blue, style = { "bold" } }
        overrides.DiagnosticHint = { fg = colors.teal, style = { "bold" } }
        overrides.GitSignsAdd = { fg = colors.green, style = { "bold" } }
        overrides.GitSignsChange = { fg = colors.yellow, style = { "bold" } }
        overrides.GitSignsDelete = { fg = colors.red, style = { "bold" } }
        overrides.WinSeparator = { fg = colors.blue, style = { "bold" } }

        if not theme_config.transparency.enable then
          overrides.Pmenu = { bg = colors.surface0, fg = colors.text }
          overrides.StatusLine = { bg = colors.base, fg = colors.text }
          overrides.StatusLineNC = { bg = colors.base, fg = colors.overlay1 }
        end

        return overrides
      end,
    },
    integrations = {
      aerial = true,
      alpha = true,
      avante = true,
      cmp = true,
      dap = { enabled = true, enable_ui = true },
      dap_ui = true,
      dropbar = { enabled = true, color_mode = true },
      fzf = true,
      gitsigns = true,
      grug_far = true,
      hop = true,
      indent_blankline = { enabled = true, scope_color = "lavender", colored_indent_levels = true },
      lsp_trouble = true,
      mason = true,
      native_lsp = {
        enabled = true,
        virtual_text = { errors = { "italic" }, hints = { "italic" } },
      },
      neotree = true,
      notify = true,
      nvimtree = true,
      render_markdown = true,
      semantic_tokens = true,
      snacks = { enabled = true },
      telescope = { enabled = true, style = "nvchad" },
      treesitter = true,
      treesitter_context = true,
      ufo = true,
      which_key = true,
      window_picker = true,
    },
  }
end

local function get_gruvbox_config()
  return {
    terminal_colors = true,
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
      strings = true,
      emphasis = true,
      comments = true,
      operators = false,
      folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true,
    contrast = "hard",
    palette_overrides = {},
    overrides = get_transparent_highlights(),
    dim_inactive = false,
    transparent_mode = theme_config.transparency.enable,
  }
end

local function get_solarized_config()
  return {
    transparent = theme_config.transparency.enable,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = { bold = true },
      variables = {},
      constants = { bold = true },
      types = { bold = true },
    },
    on_highlights = function(highlights, colors)
      local overrides = get_transparent_highlights()
      for name, hl in pairs(overrides) do
        highlights[name] = hl
      end

      highlights.Visual = { bg = colors.base02, fg = colors.base1, bold = true }

      if not theme_config.transparency.enable then
        highlights.Normal = { bg = colors.base03, fg = colors.base0 }
      end
    end,
  }
end

local function get_rose_pine_config()
  local overrides = get_transparent_highlights()
  if theme_config.transparency.enable then
    overrides.WinBar = { bg = "none", fg = "subtle" }
    overrides.WinBarNC = { bg = "none", fg = "muted" }
    overrides.NeoTreeWinSeparator = { bg = "none", fg = "muted" }
    overrides.NeoTreeVertSplit = { bg = "none", fg = "muted" }
    overrides.NeoTreeEndOfBuffer = { bg = "none", fg = "none" }
    overrides.DropBarMenuFloatBorder = { bg = "none", fg = "muted" }
  end

  return {
    theme = "roseprime",
    transparent = theme_config.transparency.enable,
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
    highlights = overrides,
  }
end

local function get_kanagawa_config()
  return {
    compile = false,
    undercurl = true,
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = theme_config.transparency.enable,
    dimInactive = false,
    terminalColors = true,
    colors = {
      palette = {},
      theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
    },
    overrides = function(colors)
      return get_transparent_highlights()
    end,
    theme = theme_config.variant,
  }
end

local function get_nightfox_config()
  return {
    options = {
      compile_path = vim.fn.stdpath("cache") .. "/nightfox",
      compile_file_suffix = "_compiled",
      transparent = theme_config.transparency.enable,
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
    groups = theme_config.transparency.enable and {
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
end

local function setup_theme()
  local base_scheme = theme_config.colorscheme:match("^[^%-]+") -- hack! had to do this to actually get this to work.
  local plugin_config = theme_config.plugins[theme_config.colorscheme]

  if base_scheme == "catppuccin" then
    require("catppuccin").setup(get_catppuccin_config())
  elseif base_scheme == "rose" or theme_config.colorscheme == "roseprime" then
    require("neomodern").setup(get_rose_pine_config())
  elseif base_scheme == "gruvbox" then
    require("gruvbox").setup(get_gruvbox_config())
  elseif base_scheme == "solarized" then
    require("solarized-osaka").setup(get_solarized_config())
  elseif base_scheme == "nord" then
    require("nightfox").setup(get_nightfox_config())
  elseif base_scheme == "kanagawa" then
    require("kanagawa").setup(get_kanagawa_config())
  end

  vim.cmd("colorscheme " .. plugin_config.colorscheme)
end

M.plugins = {
  {
    theme_config.plugins[theme_config.colorscheme].plugin,
    name = theme_config.plugins[theme_config.colorscheme].name,
    lazy = false,
    priority = 1000,
    config = setup_theme,
  },
}

return M
