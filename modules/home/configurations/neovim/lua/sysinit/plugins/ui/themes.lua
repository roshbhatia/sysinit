local json_loader = require("sysinit.utils.json_loader")
local highlight_gen = require("sysinit.utils.highlight_generator")
local theme_config =
  json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local M = {}

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
        local overrides = {}

        overrides.CursorLineNr = { fg = colors.lavender, style = { "bold" } }
        overrides.LineNr = { fg = colors.overlay1 }
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
        overrides.WinSeparator = { fg = colors.blue, style = { "bold" } }

        overrides.WildMenu = { fg = colors.base, bg = colors.pink, style = { "bold" } }
        overrides.WilderWildmenuAccent = { fg = colors.pink, style = { "bold" } }
        overrides.WilderWildmenuSelectedAccent =
          { fg = colors.base, bg = colors.pink, style = { "bold" } }
        overrides.WilderWildmenuSelected =
          { fg = colors.base, bg = colors.pink, style = { "bold" } }
        overrides.WilderWildmenuSeparator = { fg = colors.overlay1 }

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
  local overrides = {}

  local colors = {
    bg0 = "#1d2021",
    bg1 = "#3c3836",
    bg2 = "#504945",
    fg1 = "#ebdbb2",
    orange = "#fe8019",
    yellow = "#fabd2f",
  }

  if theme_config.transparency.enable then
    overrides.Pmenu = { bg = colors.bg1, fg = colors.fg1 }
    overrides.WildMenu = { bg = colors.bg2, fg = colors.orange, bold = true }
    overrides.WilderWildmenuSelected = { bg = colors.bg2, fg = colors.orange, bold = true }
    overrides.WilderWildmenuSelectedAccent = { bg = colors.bg2, fg = colors.orange, bold = true }
    overrides.PmenuSel = { bg = colors.bg2, fg = colors.orange, bold = true }
    overrides.TelescopeSelection = { bg = colors.bg2, fg = colors.orange, bold = true }
    overrides.Search = { bg = colors.yellow, fg = colors.bg0, bold = true }
    overrides.IncSearch = { bg = colors.orange, fg = colors.bg0, bold = true }
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
      highlights.Visual = { bg = colors.base02, fg = colors.base1, bold = true }
      highlights.VisualNOS = { bg = colors.base01, fg = colors.base1, bold = true }

      if theme_config.transparency.enable then
        highlights.Pmenu = { bg = colors.base02, fg = colors.base0 }
        highlights.WildMenu = { bg = colors.base01, fg = colors.blue, bold = true }
        highlights.WilderWildmenuSelected = { bg = colors.base01, fg = colors.blue, bold = true }
        highlights.WilderWildmenuSelectedAccent =
          { bg = colors.base01, fg = colors.blue, bold = true }
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
  local overrides = {}

  local colors = {
    base = "#232136",
    surface = "#2a273f",
    overlay = "#393552",
    muted = "#6e6a86",
    subtle = "#908caa",
    text = "#e0def4",
    love = "#eb6f92",
    gold = "#f6c177",
    rose = "#ea9a97",
    pine = "#3e8fb0",
    foam = "#9ccfd8",
    iris = "#c4a7e7",
  }

  if theme_config.transparency.enable then
    overrides.CursorLineNr = { bg = "none", fg = colors.foam, bold = true }
    overrides.DiffAdd = { bg = colors.foam }
    overrides.DropBarMenuFloatBorder = { bg = "none", fg = colors.subtle }
    overrides.FloatBorder = { bg = "none", fg = colors.muted }
    overrides.FloatTitle = { bg = "none", fg = colors.rose, bold = true }
    overrides.IncSearch = { bg = colors.love, fg = colors.base, bold = true }
    overrides.LineNr = { bg = "none", fg = colors.muted }
    overrides.NeoTreeEndOfBuffer = { bg = "none", fg = "none" }
    overrides.NeoTreeVertSplit = { bg = "none", fg = colors.subtle }
    overrides.NeoTreeWinSeparator = { bg = "none", fg = colors.subtle }
    overrides.NormalFloat = { bg = "none", fg = colors.text }
    overrides.Pmenu = { bg = colors.surface, fg = colors.text }
    overrides.PmenuBorder = { bg = "none", fg = colors.muted }
    overrides.PmenuSel = { bg = colors.overlay, fg = colors.foam, bold = true }
    overrides.Search = { bg = colors.gold, fg = colors.base, bold = true }
    overrides.StatusLine = { bg = "none", fg = colors.text }
    overrides.StatusLineNC = { bg = "none", fg = colors.subtle }
    overrides.TelescopeBorder = { bg = "none", fg = colors.muted }
    overrides.TelescopeSelection = { bg = colors.surface, fg = colors.foam, bold = true }
    overrides.TelescopeTitle = { bg = "none", fg = colors.rose, bold = true }
    overrides.WildMenu = { bg = colors.rose, fg = colors.base, bold = true }
    overrides.WilderWildmenuSelected = { bg = colors.rose, fg = colors.base, bold = true }
    overrides.WilderWildmenuSelectedAccent = { bg = colors.rose, fg = colors.base, bold = true }
    overrides.WinBar = { bg = "none", fg = colors.foam }
    overrides.WinBarNC = { bg = "none", fg = colors.subtle }
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
  local overrides = {}

  local colors = {
    fujiWhite = "#dcd7ba",
    waveBlue1 = "#2d4f67",
    waveBlue2 = "#223249",
    sumiInk3 = "#363646",
    sumiInk4 = "#54546D",
    winterBlue = "#7e9cd8",
  }

  if theme_config.transparency.enable then
    overrides.WinBar = { bg = "none", fg = colors.fujiWhite }
    overrides.WinBarNC = { bg = "none", fg = colors.sumiInk4 }
    overrides.NeoTreeWinSeparator = { bg = "none", fg = colors.sumiInk4 }
    overrides.NeoTreeVertSplit = { bg = "none", fg = colors.sumiInk4 }
    overrides.NeoTreeEndOfBuffer = { bg = "none", fg = "none" }
    overrides.DropBarMenuFloatBorder = { bg = "none", fg = colors.sumiInk4 }
    overrides.WildMenu = { bg = colors.waveBlue1, fg = colors.fujiWhite, bold = true }
    overrides.WilderWildmenuSelected = { bg = colors.waveBlue1, fg = colors.fujiWhite, bold = true }
    overrides.WilderWildmenuSelectedAccent =
      { bg = colors.waveBlue1, fg = colors.fujiWhite, bold = true }
    overrides.TelescopeSelection = { bg = colors.waveBlue2, fg = colors.fujiWhite, bold = true }
    overrides.Pmenu = { bg = colors.sumiInk3, fg = colors.fujiWhite }
    overrides.PmenuSel = { bg = colors.waveBlue1, fg = colors.fujiWhite, bold = true }
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
      all = theme_config.transparency.enable and {
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
        Visual = { bg = "palette.sel0", bold = true },
        VisualNOS = { bg = "palette.sel1", bold = true },
        WildMenu = { bg = "palette.sel0", fg = "palette.blue.bright", bold = true },
        WilderWildmenuSelected = {
          bg = "palette.sel0",
          fg = "palette.blue.bright",
          bold = true,
        },
        WilderWildmenuSelectedAccent = {
          bg = "palette.sel0",
          fg = "palette.blue.bright",
          bold = true,
        },
        PmenuSel = { bg = "palette.sel0", fg = "palette.blue.bright", bold = true },
        TelescopeSelection = { bg = "palette.sel0", fg = "palette.blue.bright", bold = true },
        Search = { bg = "palette.yellow.base", fg = "palette.bg1", bold = true },
        IncSearch = { bg = "palette.orange.base", fg = "palette.bg1", bold = true },
      } or {
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
      background = variant_parts[2]
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
  local overrides =
    highlight_gen.generate_core_highlights(theme_config.colors, theme_config.transparency)

  if base_scheme == "everforest" then
    local colors = {
      bg0 = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "bg"),
      bg2 = "#3d484d",
      bg4 = "#56635f",
      fg = "#d3c6aa",
      accent = "#d699b6",
      green = "#a7c080",
      blue = "#7fbbb3",
      yellow = "#dbbc7f",
      orange = "#e69875",
      red = "#e67e80",
    }

    if theme_config.transparency.enable then
      overrides.WinBar = { bg = "NONE", fg = colors.fg }
      overrides.WinBarNC = { bg = "NONE", fg = colors.bg4 }
      overrides.NeoTreeWinSeparator = { bg = "NONE" }
      overrides.NeoTreeVertSplit = { bg = "NONE" }
      overrides.NeoTreeEndOfBuffer = { bg = "NONE", fg = "NONE" }
      overrides.DropBarMenuFloatBorder = { bg = "NONE" }
      overrides.WildMenu = { fg = colors.accent, bg = colors.bg2, bold = true }
      overrides.WilderWildmenuSelected = { fg = colors.accent, bg = colors.bg2, bold = true }
      overrides.WilderWildmenuSelectedAccent = { fg = colors.accent, bg = colors.bg2, bold = true }
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

local THEME_CONFIGS = {
  catppuccin = { module = "catppuccin", config = get_catppuccin_config },
  rosepine = { module = "neomodern", config = get_rose_pine_config },
  roseprime = { module = "neomodern", config = get_rose_pine_config },
  gruvbox = { module = "gruvbox", config = get_gruvbox_config },
  solarized = { module = "solarized-osaka", config = get_solarized_config },
  nord = { module = "nightfox", config = get_nightfox_config },
  kanagawa = { module = "neomodern", config = get_kanagawa_config },
  everforest = { module = nil, config = get_everforest_config },
}

local function setup_theme()
  local plugin_config = theme_config.plugins[theme_config.colorscheme]
  local base_scheme = plugin_config.base_scheme or theme_config.colorscheme

  local theme_cfg = THEME_CONFIGS[base_scheme]
  if theme_cfg then
    local config = theme_cfg.config()
    if theme_cfg.module then
      require(theme_cfg.module).setup(config)
    end
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
