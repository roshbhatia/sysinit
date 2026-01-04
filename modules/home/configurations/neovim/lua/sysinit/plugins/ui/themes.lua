local json_loader = require("sysinit.utils.json_loader")
local highlight_gen = require("sysinit.utils.highlight_generator")

local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local c = theme_config.semanticColors
local M = {}

local theme_metadata = {
  catppuccin = {
    plugin = "catppuccin/nvim",
    setup = "catppuccin",
    colorscheme = "catppuccin",
  },
  gruvbox = {
    plugin = "sainnhe/gruvbox-material",
    setup = "gruvbox-material",
    colorscheme = "gruvbox-material",
  },
  solarized = {
    plugin = "craftzdog/solarized-osaka.nvim",
    setup = "solarized-osaka",
    colorscheme = "solarized-osaka",
  },
  ["rose-pine"] = {
    plugin = "casedami/neomodern.nvim",
    setup = "neomodern",
    colorscheme = "roseprime",
  },
  kanagawa = {
    plugin = "webhooked/kanso.nvim",
    setup = "kanso",
    colorscheme = "kanso",
  },
  nord = {
    plugin = "EdenEast/nightfox.nvim",
    setup = "nightfox",
    colorscheme = "nordfox",
  },
  everforest = {
    plugin = "sainnhe/everforest",
    setup = "everforest",
    colorscheme = "everforest",
  },
  ["black-metal"] = {
    plugin = "metalelf0/black-metal-theme-neovim",
    setup = "black-metal",
    colorscheme = "gorgoroth",
  },
  tokyonight = {
    plugin = "folke/tokyonight.nvim",
    setup = "tokyonight",
    colorscheme = "tokyonight",
  },
}

local styles = {
  comments = { "italic" },
  conditionals = { "italic" },
  loops = { "bold" },
  functions = { "bold" },
  keywords = { "bold" },
  strings = { "italic" },
  variables = {},
  numbers = { "bold" },
  booleans = { "bold", "italic" },
  properties = { "italic" },
  types = { "bold" },
  operators = { "bold" },
}

local function get_catppuccin_config()
  return {
    flavour = theme_config.variant,
    show_end_of_buffer = false,
    transparent_background = true,
    float = { transparent = true, solid = false },
    styles = styles,
    integrations = {
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
  local background = theme_config.variant or "medium"
  if background ~= "hard" and background ~= "medium" and background ~= "soft" then
    background = "medium"
  end

  vim.g.gruvbox_material_background = background
  vim.g.gruvbox_material_better_performance = 1
  vim.g.gruvbox_material_enable_italic = 1
  vim.g.gruvbox_material_disable_italic_comment = 0
  vim.g.gruvbox_material_cursor = "auto"
  vim.g.gruvbox_material_transparent_background = 2
  vim.g.gruvbox_material_dim_inactive_windows = 0
  vim.g.gruvbox_material_sign_column_background = "none"
  vim.g.gruvbox_material_spell_foreground = "none"
  vim.g.gruvbox_material_ui_contrast = "low"
  vim.g.gruvbox_material_show_eob = 0
  vim.g.gruvbox_material_float_style = "bright"
  vim.g.gruvbox_material_diagnostic_text_highlight = 0
  vim.g.gruvbox_material_diagnostic_line_highlight = 0
  vim.g.gruvbox_material_diagnostic_virtual_text = "grey"
  vim.g.gruvbox_material_current_word = "bold"
  vim.g.gruvbox_material_inlay_hints_background = "dimmed"
  vim.g.gruvbox_material_disable_terminal_colors = 0

  return {}
end

local function get_solarized_config()
  return { transparent = true, terminal_colors = true, styles = styles }
end

local function get_neomodern_config()
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
    theme = theme_config.colorscheme,
    transparent = true,
    term_colors = true,
    alt_bg = true,
    show_eob = false,
    favor_treesitter_hl = true,
    code_style = code_style,
  }
end

local function get_kanso_config()
  return {
    bold = true,
    italics = true,
    transparent = true,
    terminalColors = true,
  }
end

local function convert_styles_for_nightfox(styles)
  local converted = {}
  for k, v in pairs(styles) do
    if type(v) == "table" and #v > 0 then
      converted[k] = table.concat(v, ",")
    elseif type(v) == "table" and #v == 0 then
      converted[k] = "NONE"
    else
      converted[k] = v
    end
  end
  return converted
end
local function get_nightfox_config()
  return {
    options = {
      compile_path = vim.fn.stdpath("cache") .. "/nightfox",
      compile_file_suffix = "_compiled",
      transparent = true,
      terminal_colors = true,
      dim_inactive = false,
      module_default = true,
      styles = convert_styles_for_nightfox(styles),
      inverse = { match_paren = false, visual = false, search = false },
      modules = {
        cmp = true,
        dap_ui = true,
        fzf = true,
        gitsigns = true,
        hop = true,
        indent_blankline = true,
        native_lsp = { enabled = true, background = true },
        notify = true,
        nvimtree = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
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

local function convert_styles_for_tokyonight(styles)
  -- TokyoNight only supports these style keys
  local supported_keys = {
    comments = true,
    keywords = true,
    functions = true,
    variables = true,
    sidebars = true,
    floats = true,
  }

  local converted = {}
  for k, v in pairs(styles) do
    if supported_keys[k] then
      if type(v) == "table" and #v > 0 then
        converted[k] = {}
        for _, style in ipairs(v) do
          converted[k][style] = true
        end
      elseif type(v) == "table" and #v == 0 then
        converted[k] = {}
      else
        converted[k] = v
      end
    end
  end
  return converted
end

local function get_tokyonight_config()
  return {
    style = theme_config.variant,
    transparent = true,
    terminal_colors = true,
    styles = convert_styles_for_tokyonight(styles),
  }
end

local function apply_global_overrides()
  local overrides = highlight_gen.generate_core_highlights(c, theme_config.transparency)

  local manual_overrides = {
    CursorLineNr = { bg = "NONE", fg = c.ui.line_number_active, bold = true },
    LineNr = { bg = "NONE", fg = c.ui.line_number },

    DiffAdd = { bg = c.diff.add_bg },
    DiffChange = { bg = c.diff.change_bg },
    DiffDelete = { bg = c.diff.delete_bg },

    FloatBorder = { bg = "NONE", fg = c.syntax.comment },
    FloatTitle = { bg = "NONE", fg = c.accent.primary, bold = true },
    NormalFloat = { bg = "NONE", fg = c.foreground.primary },
    DropBarMenuFloatBorder = { bg = "NONE", fg = c.foreground.subtle },

    Search = { bg = c.plugins.search.match_bg, fg = c.plugins.search.match_fg, bold = true },
    IncSearch = {
      bg = c.plugins.search.incremental_bg,
      fg = c.plugins.search.incremental_fg,
      bold = true,
    },

    Pmenu = { bg = "NONE", fg = c.foreground.primary },
    PmenuBorder = { bg = "NONE", fg = c.plugins.completion.border },
    PmenuSel = {
      bg = c.plugins.completion.selection_bg,
      fg = c.plugins.completion.selection_fg,
      bold = true,
    },

    StatusLine = { bg = "NONE", fg = c.plugins.window.statusline_active },
    StatusLineNC = { bg = "NONE", fg = c.plugins.window.statusline_inactive },

    TelescopeBorder = { bg = "NONE", fg = c.plugins.telescope.border },
    TelescopeSelection = {
      bg = c.plugins.telescope.selection_bg,
      fg = c.plugins.telescope.selection_fg,
      bold = true,
    },
    TelescopeTitle = { bg = "NONE", fg = c.plugins.telescope.title, bold = true },

    WinBar = { bg = "NONE", fg = c.plugins.window.winbar_active },
    WinBarNC = { bg = "NONE", fg = c.plugins.window.winbar_inactive },
    WinSeparator = { fg = c.plugins.window.separator, bold = true },

    NeogitDiffContext = { bg = "NONE", fg = c.foreground.primary },
    NeogitDiffContextCursor = {
      bg = c.background.secondary,
      fg = c.foreground.primary,
      bold = true,
    },
    NeogitDiffContextHighlight = { bg = c.background.secondary, fg = c.foreground.primary },
    NeogitDiffAdd = { bg = c.diff.add_bg, fg = c.diff.add },
    NeogitDiffAddCursor = { bg = c.diff.add_bg, fg = c.diff.add, bold = true },
    NeogitDiffAddHighlight = { bg = c.diff.add_bg, fg = c.diff.add },
    NeogitDiffDelete = { bg = c.diff.delete_bg, fg = c.diff.delete },
    NeogitDiffDeleteCursor = { bg = c.diff.delete_bg, fg = c.diff.delete, bold = true },
    NeogitDiffDeleteHighlight = { bg = c.diff.delete_bg, fg = c.diff.delete },

    DiagnosticError = { fg = c.semantic.error, bold = true },
    DiagnosticWarn = { fg = c.semantic.warning, bold = true },
    DiagnosticInfo = { fg = c.semantic.info, bold = true },
    DiagnosticHint = { fg = c.semantic.info, bold = true },

    WilderSelected = {
      fg = c.plugins.completion.selection_fg,
      bold = true,
    },
    WilderAccent = {
      fg = c.accent.primary,
      bold = true,
    },
    WilderWildmenuSelected = {
      fg = c.plugins.completion.selection_fg,
      bold = true,
      bg = "NONE",
    },
    WilderWildmenuAccent = {
      fg = c.accent.primary,
      bold = true,
    },
    WilderSeparator = { fg = c.syntax.comment },
    WilderSpinner = { fg = c.syntax.comment, bold = true },

    OutlineCurrent = { fg = c.accent.primary, bold = true, bg = c.background.secondary },
    OutlineGuides = { fg = c.syntax.comment },
    OutlineFoldMarker = { fg = c.foreground.subtle },
    OutlineDetails = { fg = c.syntax.comment },
    OutlineLineno = { fg = c.ui.line_number },
    OutlineJumpHighlight = { fg = c.background.primary, bg = c.accent.primary },

    NeoTreeNormal = { bg = "NONE", fg = c.foreground.primary },
    NeoTreeNormalNC = { bg = "NONE", fg = c.foreground.primary },
    NeoTreeEndOfBuffer = { bg = "NONE", fg = "NONE" },
    NeoTreeFloatBorder = { bg = "NONE", fg = c.syntax.comment },
    NeoTreeFloatTitle = { bg = "NONE", fg = c.accent.primary, bold = true },
    NeoTreeTitleBar = { bg = "NONE", fg = c.accent.primary, bold = true },
    NeoTreeCursorLine = { bg = c.background.secondary, bold = true },
    NeoTreeDimText = { fg = c.foreground.muted },
    NeoTreeDirectoryIcon = { fg = c.accent.secondary },
    NeoTreeDirectoryName = { fg = c.foreground.primary },
    NeoTreeFileName = { fg = c.foreground.primary },
    NeoTreeFileIcon = { fg = c.foreground.subtle },
    NeoTreeFileNameOpened = { fg = c.accent.primary, bold = true },
    NeoTreeFilterTerm = { fg = c.accent.primary, bold = true },
    NeoTreeFloatNormal = { bg = "NONE", fg = c.foreground.primary },
    NeoTreeGitAdded = { fg = c.diff.add },
    NeoTreeGitConflict = { fg = c.semantic.error, bold = true },
    NeoTreeGitDeleted = { fg = c.diff.delete },
    NeoTreeGitIgnored = { fg = c.foreground.muted },
    NeoTreeGitModified = { fg = c.diff.change },
    NeoTreeGitUnstaged = { fg = c.semantic.warning },
    NeoTreeGitUntracked = { fg = c.foreground.subtle },
    NeoTreeGitStaged = { fg = c.diff.add },
    NeoTreeIndentMarker = { fg = c.syntax.comment },
    NeoTreeExpander = { fg = c.syntax.comment },
    NeoTreeRootName = { fg = c.accent.primary, bold = true },
    NeoTreeSymbolicLinkTarget = { fg = c.accent.secondary },
    NeoTreeTabActive = { bg = c.background.secondary, fg = c.accent.primary, bold = true },
    NeoTreeTabInactive = { bg = "NONE", fg = c.foreground.muted },
    NeoTreeTabSeparatorActive = { bg = c.background.secondary, fg = c.accent.primary },
    NeoTreeTabSeparatorInactive = { bg = "NONE", fg = c.syntax.comment },
    NeoTreeWinSeparator = { fg = c.plugins.window.separator, bold = true },
  }

  for group, opts in pairs(manual_overrides) do
    overrides[group] = opts
  end

  for name, hl in pairs(overrides) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

local function get_plugin_config()
  local scheme = theme_config.colorscheme
  local metadata = theme_metadata[scheme]

  if not metadata then
    return nil
  end

  return metadata
end

local function setup_theme()
  local active_scheme = theme_config.colorscheme
  local plugin_config = get_plugin_config()

  if not plugin_config then
    error("No theme config found for: " .. active_scheme)
  end

  local config_funcs = {
    catppuccin = get_catppuccin_config,
    gruvbox = get_gruvbox_config,
    solarized = get_solarized_config,
    nord = get_nightfox_config,
    everforest = get_everforest_config,
    ["rose-pine"] = get_neomodern_config,
    kanagawa = get_kanso_config,
    tokyonight = get_tokyonight_config,
  }
  local config_func = config_funcs[active_scheme]

  if config_func then
    local config = config_func()
    if plugin_config.setup == "everforest" or plugin_config.setup == "gruvbox-material" then
      -- These themes use vim.g variables instead of setup
    else
      require(plugin_config.setup).setup(config)
    end
  end

  vim.cmd.colorscheme(plugin_config.colorscheme)
  apply_global_overrides()

  vim.api.nvim_create_autocmd(
    { "ColorScheme", "CmdLineEnter" },
    { pattern = plugin_config.colorscheme, callback = apply_global_overrides }
  )
end

local function build_plugins()
  local scheme = theme_config.colorscheme
  local metadata = theme_metadata[scheme]

  if not metadata then
    error("Unknown theme: " .. scheme)
  end

  return {
    {
      metadata.plugin,
      lazy = false,
      priority = 1000,
      config = setup_theme,
    },
  }
end

M.plugins = build_plugins()

return M
