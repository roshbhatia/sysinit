local json_loader = require("sysinit.utils.json_loader")
local highlight_gen = require("sysinit.utils.highlight_generator")
local theme_config =
  json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local M = {}

local function get_transparent_highlights()
  if not theme_config.transparency.enable then
    return {}
  end

  return {
    BlinkCmpDoc = { bg = "none" },
    BlinkCmpDocBorder = { bg = "none" },
    BlinkCmpMenu = { bg = "none" },
    BlinkCmpMenuBorder = { bg = "none" },
    BlinkCmpSignatureHelp = { bg = "none" },
    BlinkCmpSignatureHelpBorder = { bg = "none" },
    ColorColumn = { bg = "none" },
    CursorColumn = { bg = "none" },
    CursorLine = { bg = "none" },
    CursorLineFold = { bg = "none" },
    CursorLineNr = { bg = "none" },
    CursorLineSign = { bg = "none" },
    DiagnosticVirtualTextError = { bg = "none" },
    DiagnosticVirtualTextHint = { bg = "none" },
    DiagnosticVirtualTextInfo = { bg = "none" },
    DiagnosticVirtualTextWarn = { bg = "none" },
    DropBarCurrentContext = { bg = "none" },
    DropBarIconKindDefault = { bg = "none" },
    DropBarIconKindDefaultNC = { bg = "none" },
    DropBarMenuFloatBorder = { bg = "none" },
    DropBarMenuNormalFloat = { bg = "none" },
    EdgyIcon = { bg = "none" },
    EdgyIconActive = { bg = "none" },
    EdgyTitle = { bg = "none" },
    FloatBorder = { bg = "none" },
    FloatTitle = { bg = "none" },
    FoldColumn = { bg = "none" },
    GitSignsAdd = { bg = "none" },
    GitSignsAddCul = { bg = "none" },
    GitSignsChange = { bg = "none" },
    GitSignsChangeCul = { bg = "none" },
    GitSignsDelete = { bg = "none" },
    GitSignsDeleteCul = { bg = "none" },
    LazyNormal = { bg = "none" },
    LineNr = { bg = "none" },
    LineNrAbove = { bg = "none" },
    LineNrBelow = { bg = "none" },
    MsgSeparator = { bg = "none" },
    NeoTreeEndOfBuffer = { bg = "none" },
    NeoTreeNormal = { bg = "none" },
    NeoTreeNormalNC = { bg = "none" },
    NeoTreeVertSplit = { bg = "none" },
    NeoTreeWinSeparator = { bg = "none" },
    Normal = { bg = "none" },
    NormalFloat = { bg = "none" },
    NormalNC = { bg = "none" },
    NotifyBackground = { bg = "none" },
    Number = { bg = "none" },
    Pmenu = { bg = "none" },
    PmenuBorder = { bg = "none" },
    PmenuExtra = { bg = "none" },
    PmenuExtraSel = { bg = "none" },
    PmenuKind = { bg = "none" },
    PmenuKindSel = { bg = "none" },
    PmenuMatch = { bg = "none" },
    PmenuMatchSel = { bg = "none" },
    PmenuSbar = { bg = "none" },
    PmenuThumb = { bg = "none" },
    Question = { bg = "none" },
    QuickFixLine = { bg = "none" },
    Search = { bg = "none" },
    SignColumn = { bg = "none" },
    SnacksIndentScope = { bg = "none" },
    SnacksDashboardDesc = { bg = "none" },
    SnacksDashboardFile = { bg = "none" },
    SnacksDashboardFooter = { bg = "none" },
    SnacksDashboardHeader = { bg = "none" },
    SnacksDashboardIcon = { bg = "none" },
    SnacksDashboardKey = { bg = "none" },
    SnacksDashboardTitle = { bg = "none" },
    StatusLine = { bg = "none" },
    StatusLineNC = { bg = "none" },
    TabLine = { bg = "none" },
    TabLineFill = { bg = "none" },
    TabLineModified = { bg = "none" },
    TabLineModifiedSelected = { bg = "none" },
    TabLineSelected = { bg = "none" },
    TelescopeNormal = { bg = "none" },
    TelescopePreviewNormal = { bg = "none" },
    TelescopePromptNormal = { bg = "none" },
    TelescopeResultsNormal = { bg = "none" },
    TelescopeBorder = { bg = "none" },
    TelescopePreviewBorder = { bg = "none" },
    TelescopePromptBorder = { bg = "none" },
    TelescopeResultsBorder = { bg = "none" },
    TelescopeTitle = { bg = "none" },
    Terminal = { bg = "none" },
    TerminalNormal = { bg = "none" },
    ToolbarButton = { bg = "none" },
    ToolbarLine = { bg = "none" },
    VertSplit = { bg = "none" },
    WildMenu = { bg = "none" },
    WilderWildmenu = { bg = "none" },
    WilderWildmenuAccent = { bg = "none" },
    WilderWildmenuSelected = { bg = "none" },
    WilderWildmenuSelectedAccent = { bg = "none" },
    WinBar = { bg = "none" },
    WinBarNC = { bg = "none" },
    WinSeparator = { bg = "none" },
  }
end

local function get_catppuccin_config()
  return {
    flavour = theme_config.variant,
    show_end_of_buffer = false,
    transparent_background = theme_config.transparency.enable,
    float = {
      transparent = theme_config.transparency.enable,
      solid = false,
    },
    color_overrides = {},
    highlight_overrides = {
      ---@diagnostic disable-next-line: unused-local
      [theme_config.variant] = function(colors)
        return get_transparent_highlights()
      end,
    },
    integrations = {
      aerial = true,
      cmp = true,
      dap = { enabled = true, enable_ui = true },
      dap_ui = true,
      dropbar = { enabled = true, color_mode = true },
      fzf = true,
      gitsigns = true,
      grug_far = true,
      hop = true,
      indent_blankline = { enabled = true, scope_color = "lavender", colored_indent_levels = true },
      native_lsp = {
        enabled = true,
        virtual_text = { errors = { "italic" }, hints = { "italic" } },
      },
      neotree = true,
      notify = true,
      nvimtree = true,
      markview = true,
      semantic_tokens = true,
      snacks = { enabled = true },
      telescope = { enabled = true, style = "nvchad" },
      treesitter = true,
      treesitter_context = true,
      which_key = true,
    },
  }
end

local function get_gruvbox_config()
  local overrides = get_transparent_highlights()
  overrides.WildMenu = { bg = "none", fg = "none" }
  overrides.WilderWildmenuSelected = { bg = "none" }
  overrides.WilderWildmenuSelectedAccent = { bg = "none" }

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
    overrides = overrides,
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
    overrides.WilderWildmenuSelectedAccent = { bg = "subtle", fg = "muted" }
    overrides.TelescopeSelection = { bg = "subtle", fg = "muted" }
  end

  local code_style = {
    comments = "none",
    conditionals = "none",
    functions = "bold",
    keywords = "bold",
    headings = "italic",
    operators = "none",
    keyword_return = "bold",
    strings = "italic",
    variables = "none",
  }

  return {
    theme = "roseprime",
    transparent = theme_config.transparency.enable,
    term_colors = true,
    alt_bg = true,
    show_eob = false,
    favor_treesitter_hl = true,
    code_style = code_style,
    highlight_overrides = overrides,
  }
end

local function get_kanagawa_config()
  local overrides = get_transparent_highlights()
  if theme_config.transparency.enable then
    overrides.WinBar = { bg = "none", fg = "subtle" }
    overrides.WinBarNC = { bg = "none", fg = "muted" }
    overrides.NeoTreeWinSeparator = { bg = "none", fg = "muted" }
    overrides.NeoTreeVertSplit = { bg = "none", fg = "muted" }
    overrides.NeoTreeEndOfBuffer = { bg = "none", fg = "none" }
    overrides.DropBarMenuFloatBorder = { bg = "none", fg = "muted" }
    overrides.WilderWildmenuSelected = { bg = "subtle", fg = "muted" }
    overrides.WilderWildmenuSelectedAccent = { bg = "subtle", fg = "muted" }
    overrides.TelescopeSelection = { bg = "subtle", fg = "muted" }
  end

  local code_style = {
    comments = "none",
    conditionals = "none",
    functions = "bold",
    keywords = "bold",
    headings = "italic",
    operators = "none",
    keyword_return = "bold",
    strings = "italic",
    variables = "none",
  }

  return {
    theme = "gyokuro",
    transparent = theme_config.transparency.enable,
    term_colors = true,
    alt_bg = true,
    show_eob = false,
    favor_treesitter_hl = true,
    code_style = code_style,
    highlights = overrides,
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
      inverse = {
        match_paren = false,
        visual = false,
        search = false,
      },
      modules = {
        aerial = true,
        cmp = true,
        dap_ui = true,
        fzf = true,
        gitsigns = true,
        hop = true,
        indent_blankline = true,
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
    groups = {
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
        WilderWildmenu = { bg = "none" },
        WilderWildmenuAccent = { bg = "none" },
        WilderWildmenuSelected = { bg = "none" },
        WilderWildmenuSelectedAccent = { bg = "none" },
      },
    },
  }
end

local function get_everforest_config()
  local background = "medium"
  if theme_config.variant then
    local variant_parts = vim.split(theme_config.variant, "-")
    if #variant_parts >= 2 then
      background = variant_parts[2]
    end
  end

  vim.g.everforest_background = background
  vim.g.everforest_better_performance = 1
  vim.g.everforest_enable_italic = 1
  vim.g.everforest_disable_italic_comment = 0
  vim.g.everforest_cursor = "auto"
  vim.g.everforest_transparent_background = 2
  vim.g.everforest_dim_inactive_windows = 0
  vim.g.everforest_sign_column_background = "none"
  vim.g.everforest_spell_foreground = "none"
  vim.g.everforest_ui_contrast = "low"
  vim.g.everforest_show_eob = 0
  vim.g.everforest_float_style = "bright"
  vim.g.everforest_diagnostic_text_highlight = 0
  vim.g.everforest_diagnostic_line_highlight = 0
  vim.g.everforest_diagnostic_virtual_text = "grey"
  vim.g.everforest_current_word = "bold"
  vim.g.everforest_inlay_hints_background = "dimmed"
  vim.g.everforest_disable_terminal_colors = 0

  return {}
end

local function apply_post_colorscheme_overrides(base_scheme)
  local c = theme_config.semanticColors
  local overrides = highlight_gen.generate_core_highlights(c, theme_config.transparency)

  local transparent_overrides = get_transparent_highlights()
  for name, hl in pairs(transparent_overrides) do
    overrides[name] = hl
  end

  for name, hl in pairs(overrides) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

local THEME_CONFIGS = {
  catppuccin = { module = "catppuccin", config = get_catppuccin_config },
  ["rose-pine"] = { module = "neomodern", config = get_rose_pine_config },
  gruvbox = { module = "gruvbox", config = get_gruvbox_config },
  solarized = { module = "solarized-osaka", config = get_solarized_config },
  nord = { module = "nightfox", config = get_nightfox_config },
  kanagawa = { module = "neomodern", config = get_kanagawa_config },
  everforest = { module = nil, config = get_everforest_config },
}

local function setup_theme()
  local base_scheme = theme_config.colorscheme

  local theme_cfg = THEME_CONFIGS[base_scheme]
  if theme_cfg then
    local config = theme_cfg.config()
    if theme_cfg.module then
      require(theme_cfg.module).setup(config)
    end
  end

  vim.cmd("colorscheme " .. theme_config.theme_colorscheme)

  apply_post_colorscheme_overrides(base_scheme)

  vim.api.nvim_create_autocmd({ "ColorScheme", "CmdLineEnter" }, {
    pattern = theme_config.theme_colorscheme,
    callback = function()
      apply_post_colorscheme_overrides(base_scheme)
    end,
  })
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
