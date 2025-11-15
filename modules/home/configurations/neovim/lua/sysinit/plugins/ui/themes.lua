local json_loader = require("sysinit.utils.json_loader")
local theme_config =
  json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local M = {}

local function get_transparent_highlights()
  local highlights = {
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
    Pmenu = { bg = "none" },
    PmenuBorder = { bg = "none" },
    PmenuSbar = { bg = "none" },
    PmenuThumb = { bg = "none" },
    SignColumn = { bg = "none" },
    StatusLine = { bg = "none" },
    StatusLineNC = { bg = "none" },
    StatusLineTerm = { bg = "none" },
    StatusLineTermNC = { bg = "none" },
    TabLine = { bg = "none" },
    TabLineFill = { bg = "none" },
    TelescopeBorder = { bg = "none" },
    TelescopeNormal = { bg = "none" },
    TelescopeSelection = { bg = "none" },
    TreesitterContext = { bg = "none" },
    TreesitterContextLineNumber = { bg = "none" },
    WhichKeyBorder = { bg = "none" },
    WhichKeyFloat = { bg = "none" },
    WinBar = { bg = "none" },
    WinBarNC = { bg = "none" },
    WinSeparator = { bg = "none" },
  }

  -- Only return transparency overrides when enabled
  if not theme_config.transparency.enable then
    return {}
  end

  return highlights
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
      keywords = { "bold" },
      strings = {},
      variables = {},
      numbers = { "bold" },
      booleans = { "bold", "italic" },
      properties = {},
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
        overrides.Visual = { bg = colors.surface2, fg = colors.text, style = { "bold" } }
        overrides.VisualNOS = { bg = colors.surface1, fg = colors.text, style = { "bold" } }
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

  -- Enhanced visual mode highlighting using gruvbox semantic colors
  -- These work across hard/medium/soft variants
  overrides.Visual = { bg = "GruvboxBg2", fg = "GruvboxFg1", bold = true, reverse = false }
  overrides.VisualNOS = { bg = "GruvboxBg1", fg = "GruvboxFg1", bold = true }

  if theme_config.transparency.enable then
    -- Enhanced contrast for transparent background
    overrides.Pmenu = { bg = "GruvboxBg1", fg = "GruvboxFg1" }
    overrides.PmenuSel = { bg = "GruvboxBg2", fg = "GruvboxOrange", bold = true }
    overrides.TelescopeSelection = { bg = "GruvboxBg2", fg = "GruvboxOrange", bold = true }
    overrides.Search = { bg = "GruvboxYellow", fg = "GruvboxBg0", bold = true }
    overrides.IncSearch = { bg = "GruvboxOrange", fg = "GruvboxBg0", bold = true }
  end

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

      -- Enhanced visual mode highlighting with better contrast
      highlights.Visual = { bg = colors.base02, fg = colors.base1, bold = true }
      highlights.VisualNOS = { bg = colors.base01, fg = colors.base1, bold = true }

      if theme_config.transparency.enable then
        -- Enhanced contrast for transparent background
        highlights.Pmenu = { bg = colors.base02, fg = colors.base0 }
        highlights.PmenuSel = { bg = colors.base01, fg = colors.blue, bold = true }
        highlights.TelescopeSelection = { bg = colors.base01, fg = colors.blue, bold = true }
        highlights.Search = { bg = colors.yellow, fg = colors.base03, bold = true }
        highlights.IncSearch = { bg = colors.orange, fg = colors.base03, bold = true }
        highlights.CursorLineNr = { fg = colors.blue, bold = true }
        highlights.LineNr = { fg = colors.base01 }
      else
        highlights.Normal = { bg = colors.base03, fg = colors.base0 }
      end
    end,
  }
end

local function get_rose_pine_config()
  local overrides = get_transparent_highlights()

  -- Rosé Pine palette colors (work for all variants: main, moon, dawn)
  local palette = {
    base = "base",
    surface = "surface",
    overlay = "overlay",
    muted = "muted",
    subtle = "subtle",
    text = "text",
    love = "love",
    gold = "gold",
    rose = "rose",
    pine = "pine",
    foam = "foam",
    iris = "iris",
    highlight_low = "highlight_low",
    highlight_med = "highlight_med",
    highlight_high = "highlight_high",
  }

  -- Enhanced visual mode highlighting (works with transparency)
  overrides.Visual = { bg = palette.highlight_med, fg = palette.text, bold = true }
  overrides.VisualNOS = { bg = palette.highlight_low, fg = palette.text, bold = true }

  if theme_config.transparency.enable then
    -- Enhanced transparency overrides for better legibility
    overrides.WinBar = { bg = "none", fg = palette.foam }
    overrides.WinBarNC = { bg = "none", fg = palette.subtle }
    overrides.NeoTreeWinSeparator = { bg = "none", fg = palette.subtle }
    overrides.NeoTreeVertSplit = { bg = "none", fg = palette.subtle }
    overrides.NeoTreeEndOfBuffer = { bg = "none", fg = "none" }
    overrides.DropBarMenuFloatBorder = { bg = "none", fg = palette.subtle }
    overrides.WilderWildmenuSelectedAccent = { bg = palette.surface, fg = palette.foam }
    overrides.TelescopeSelection = { bg = palette.surface, fg = palette.foam, bold = true }
    overrides.TelescopeBorder = { bg = "none", fg = palette.muted }
    overrides.TelescopeTitle = { bg = "none", fg = palette.rose, bold = true }
    overrides.NormalFloat = { bg = "none", fg = palette.text }
    overrides.FloatBorder = { bg = "none", fg = palette.muted }
    overrides.FloatTitle = { bg = "none", fg = palette.rose, bold = true }
    overrides.Pmenu = { bg = palette.surface, fg = palette.text }
    overrides.PmenuSel = { bg = palette.overlay, fg = palette.foam, bold = true }
    overrides.PmenuBorder = { bg = "none", fg = palette.muted }
    overrides.StatusLine = { bg = "none", fg = palette.text }
    overrides.StatusLineNC = { bg = "none", fg = palette.subtle }
    overrides.LineNr = { bg = "none", fg = palette.muted }
    overrides.CursorLineNr = { bg = "none", fg = palette.foam, bold = true }
    overrides.Search = { bg = palette.gold, fg = palette.base, bold = true }
    overrides.IncSearch = { bg = palette.love, fg = palette.base, bold = true }
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
    highlights = overrides,
  }
end

local function get_kanagawa_config()
  local overrides = get_transparent_highlights()

  -- Kanagawa palette (semantic color names that work across variants)
  local palette = {
    fujiWhite = "fujiWhite",
    waveBlue1 = "waveBlue1",
    waveBlue2 = "waveBlue2",
    winterBlue = "winterBlue",
    sumiInk3 = "sumiInk3",
  }

  -- Enhanced visual mode highlighting (higher contrast for transparency)
  overrides.Visual = { bg = palette.waveBlue1, fg = palette.fujiWhite, bold = true }
  overrides.VisualNOS = { bg = palette.waveBlue2, fg = palette.fujiWhite, bold = true }

  if theme_config.transparency.enable then
    overrides.WinBar = { bg = "none", fg = palette.fujiWhite }
    overrides.WinBarNC = { bg = "none", fg = "subtle" }
    overrides.NeoTreeWinSeparator = { bg = "none", fg = "muted" }
    overrides.NeoTreeVertSplit = { bg = "none", fg = "muted" }
    overrides.NeoTreeEndOfBuffer = { bg = "none", fg = "none" }
    overrides.DropBarMenuFloatBorder = { bg = "none", fg = "muted" }
    overrides.WilderWildmenuSelectedAccent =
      { bg = palette.waveBlue2, fg = palette.fujiWhite, bold = true }
    overrides.TelescopeSelection = { bg = palette.waveBlue2, fg = palette.fujiWhite, bold = true }
    overrides.Pmenu = { bg = palette.sumiInk3, fg = palette.fujiWhite }
    overrides.PmenuSel = { bg = palette.waveBlue1, fg = palette.fujiWhite, bold = true }
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
      all = theme_config.transparency.enable
          and {
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
            -- Enhanced visual selection with bg for better visibility
            Visual = { bg = "palette.sel0", bold = true },
            VisualNOS = { bg = "palette.sel1", bold = true },
            -- Better contrast for selections
            PmenuSel = { bg = "palette.sel0", fg = "palette.blue.bright", bold = true },
            TelescopeSelection = { bg = "palette.sel0", fg = "palette.blue.bright", bold = true },
            Search = { bg = "palette.yellow.base", fg = "palette.bg1", bold = true },
            IncSearch = { bg = "palette.orange.base", fg = "palette.bg1", bold = true },
          }
        or {
          -- Non-transparent mode still gets enhanced visual selection
          Visual = { bg = "palette.sel0", bold = true },
          VisualNOS = { bg = "palette.sel1", bold = true },
        },
    },
  }
end

local function get_everforest_config()
  local background = "medium"
  if theme_config.variant then
    local variant_parts = vim.split(theme_config.variant, "-")
    if #variant_parts >= 2 then
      background = variant_parts[2] -- "hard", "medium", or "soft"
    end
  end

  vim.g.everforest_background = background
  vim.g.everforest_better_performance = 1
  vim.g.everforest_enable_italic = 1
  vim.g.everforest_disable_italic_comment = 0
  vim.g.everforest_cursor = "auto"
  vim.g.everforest_transparent_background = theme_config.transparency.enable and 2 or 0
  vim.g.everforest_dim_inactive_windows = 0
  vim.g.everforest_sign_column_background = "none"
  vim.g.everforest_spell_foreground = "none"
  vim.g.everforest_ui_contrast = "low"
  vim.g.everforest_show_eob = 0
  vim.g.everforest_float_style = "bright"
  vim.g.everforest_diagnostic_text_highlight = 0
  vim.g.everforest_diagnostic_line_highlight = 0
  vim.g.everforest_diagnostic_virtual_text = "grey"
  vim.g.everforest_current_word = theme_config.transparency.enable and "bold" or "grey background"
  vim.g.everforest_inlay_hints_background = "dimmed"
  vim.g.everforest_disable_terminal_colors = 0

  return {}
end

local function apply_post_colorscheme_overrides(base_scheme)
  local overrides = get_transparent_highlights()

  if base_scheme == "everforest" then
    -- Everforest semantic palette colors (work across hard/medium/soft variants)
    local colors = {
      -- Get colors from the actual colorscheme after it loads
      bg0 = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "bg"),
      bg2 = "#3d484d", -- Hard variant bg2
      bg4 = "#56635f", -- Visual selection background
      fg = "#d3c6aa", -- Main foreground
      accent = "#d699b6", -- Purple accent
      green = "#a7c080",
      blue = "#7fbbb3",
      yellow = "#dbbc7f",
      orange = "#e69875",
      red = "#e67e80",
    }

    -- Enhanced visual mode highlighting
    overrides.Visual = { bg = colors.bg4, fg = colors.fg, bold = true }
    overrides.VisualNOS = { bg = colors.bg2, fg = colors.fg, bold = true }

    if theme_config.transparency.enable then
      overrides.WinBar = { bg = "NONE", fg = colors.fg }
      overrides.WinBarNC = { bg = "NONE", fg = colors.bg4 }
      overrides.NeoTreeWinSeparator = { bg = "NONE" }
      overrides.NeoTreeVertSplit = { bg = "NONE" }
      overrides.NeoTreeEndOfBuffer = { bg = "NONE", fg = "NONE" }
      overrides.DropBarMenuFloatBorder = { bg = "NONE" }
      overrides.WilderWildmenuAccent = { fg = colors.accent, bg = "NONE" }
      overrides.WilderWildmenuSelectedAccent =
        { fg = colors.accent, bg = "NONE", bold = true, underline = true }
      overrides.WilderWildmenuSelected = { link = "WilderWildmenuSelectedAccent" }
      overrides.WilderWildmenuSeparator = { fg = colors.accent, bg = "NONE" }
      overrides.WildMenu = { link = "WilderWildmenuSelectedAccent" }
      overrides.PmenuSel = { fg = colors.accent, bg = colors.bg2, bold = true }
      overrides.TelescopeSelection = { bg = colors.bg2, fg = colors.blue, bold = true }
      overrides.Search = { bg = colors.yellow, fg = colors.bg0, bold = true }
      overrides.IncSearch = { bg = colors.orange, fg = colors.bg0, bold = true }
    end
  end

  for name, hl in pairs(overrides) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

local function setup_theme()
  local plugin_config = theme_config.plugins[theme_config.colorscheme]
  local base_scheme = plugin_config.base_scheme or theme_config.colorscheme

  local theme_setups = {
    catppuccin = function()
      require("catppuccin").setup(get_catppuccin_config())
    end,
    rosepine = function()
      require("neomodern").setup(get_rose_pine_config())
    end,
    roseprime = function()
      require("neomodern").setup(get_rose_pine_config())
    end,
    gruvbox = function()
      require("gruvbox").setup(get_gruvbox_config())
    end,
    solarized = function()
      require("solarized-osaka").setup(get_solarized_config())
    end,
    nord = function()
      require("nightfox").setup(get_nightfox_config())
    end,
    kanagawa = function()
      require("neomodern").setup(get_kanagawa_config())
    end,
    everforest = function()
      get_everforest_config()
    end,
  }

  local setup_fn = theme_setups[base_scheme]
  if setup_fn then
    setup_fn()
  end

  vim.cmd("colorscheme " .. plugin_config.colorscheme)

  apply_post_colorscheme_overrides(base_scheme)
  vim.api.nvim_create_autocmd({ "ColorScheme", "CmdLineEnter" }, {
    pattern = plugin_config.colorscheme,
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
