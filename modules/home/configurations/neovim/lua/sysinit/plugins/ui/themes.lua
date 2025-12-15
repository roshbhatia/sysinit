-- modules/home/configurations/neovim/lua/sysinit/plugins/ui/themes.lua
-- Purpose: Theme configuration using shared theme system (no hardcoded colors)

local json_loader = require("sysinit.utils.json_loader")
local highlight_gen = require("sysinit.utils.highlight_generator")
local theme_config =
  json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local M = {}

local function get_common_styles()
  return {
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
end

local function get_catppuccin_config()
  local c = theme_config.semanticColors
  local p = theme_config.palette

  return {
    flavour = theme_config.variant,
    show_end_of_buffer = false,
    transparent_background = true,
    float = {
      transparent = true,
      solid = false,
    },
    styles = get_common_styles(),
    color_overrides = {},
    highlight_overrides = {
      [theme_config.variant] = function(colors)
        local overrides = {}

        overrides.CursorLineNr = { fg = c.accent.primary, style = { "bold" } }
        overrides.LineNr = { fg = c.ui.line_number }
        overrides.Search =
          { bg = c.semantic.warning, fg = c.background.primary, style = { "bold" } }
        overrides.IncSearch =
          { bg = c.semantic.error, fg = c.background.primary, style = { "bold" } }
        overrides.PmenuSel = {
          bg = c.plugins.completion.selection_bg,
          fg = c.plugins.completion.selection_fg,
          style = { "bold" },
        }
        overrides.PmenuBorder = { fg = c.plugins.completion.border }
        overrides.FloatBorder = { fg = c.plugins.window.float_border }
        overrides.FloatTitle = { fg = c.plugins.window.float_title, style = { "bold" } }
        overrides.TelescopeBorder = { fg = c.plugins.telescope.border }
        overrides.TelescopeSelection = {
          bg = c.plugins.telescope.selection_bg,
          fg = c.plugins.telescope.selection_fg,
          style = { "bold" },
        }
        overrides.TelescopeTitle = { fg = c.plugins.telescope.title, style = { "bold" } }
        overrides.WhichKeyBorder = { fg = c.plugins.window.border }
        overrides.DiagnosticError = { fg = c.semantic.error, style = { "bold" } }
        overrides.DiagnosticWarn = { fg = c.semantic.warning, style = { "bold" } }
        overrides.DiagnosticInfo = { fg = c.semantic.info, style = { "bold" } }
        overrides.DiagnosticHint = { fg = c.semantic.info, style = { "bold" } }
        overrides.WinSeparator = { fg = c.plugins.window.separator, style = { "bold" } }

        overrides.WildMenu =
          { fg = c.background.primary, bg = c.accent.primary, style = { "bold" } }
        overrides.WilderWildmenuAccent = { fg = c.accent.primary, style = { "bold" } }
        overrides.WilderWildmenuSelectedAccent =
          { fg = c.background.primary, bg = c.accent.primary, style = { "bold" } }
        overrides.WilderWildmenuSelected =
          { fg = c.background.primary, bg = c.accent.primary, style = { "bold" } }
        overrides.WilderWildmenuSeparator = { fg = c.ui.line_number }

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
  local c = theme_config.semanticColors
  local overrides = {}

  overrides.Pmenu = { bg = c.background.secondary, fg = c.foreground.primary }
  overrides.WildMenu = { bg = c.background.tertiary, fg = c.accent.primary, bold = true }
  overrides.WilderWildmenuSelected =
    { bg = c.background.tertiary, fg = c.accent.primary, bold = true }
  overrides.WilderWildmenuSelectedAccent =
    { bg = c.background.tertiary, fg = c.accent.primary, bold = true }
  overrides.PmenuSel =
    { bg = c.plugins.completion.selection_bg, fg = c.plugins.completion.selection_fg, bold = true }
  overrides.TelescopeSelection =
    { bg = c.plugins.telescope.selection_bg, fg = c.plugins.telescope.selection_fg, bold = true }
  overrides.Search = { bg = c.semantic.warning, fg = c.background.primary, bold = true }
  overrides.IncSearch = { bg = c.semantic.error, fg = c.background.primary, bold = true }

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
    transparent_mode = true,
  }
end

local function get_solarized_config()
  local c = theme_config.semanticColors

  return {
    transparent = true,
    terminal_colors = true,
    styles = get_common_styles(),
    on_highlights = function(highlights, colors)
      highlights.Visual = { bg = c.ui.selection, fg = c.foreground.primary, bold = true }
      highlights.VisualNOS = { bg = c.ui.selection, fg = c.foreground.primary, bold = true }

      highlights.Pmenu = { bg = c.background.secondary, fg = c.foreground.primary }
      highlights.WildMenu = { bg = c.background.tertiary, fg = c.accent.primary, bold = true }
      highlights.WilderWildmenuSelected =
        { bg = c.background.tertiary, fg = c.accent.primary, bold = true }
      highlights.WilderWildmenuSelectedAccent =
        { bg = c.background.tertiary, fg = c.accent.primary, bold = true }
      highlights.PmenuSel = {
        bg = c.plugins.completion.selection_bg,
        fg = c.plugins.completion.selection_fg,
        bold = true,
      }
      highlights.TelescopeSelection = {
        bg = c.plugins.telescope.selection_bg,
        fg = c.plugins.telescope.selection_fg,
        bold = true,
      }
      highlights.Search =
        { bg = c.plugins.search.match_bg, fg = c.plugins.search.match_fg, bold = true }
      highlights.IncSearch =
        { bg = c.plugins.search.incremental_bg, fg = c.plugins.search.incremental_fg, bold = true }
      highlights.CursorLineNr = { fg = c.ui.line_number_active, bold = true }
      highlights.LineNr = { fg = c.ui.line_number }
    end,
  }
end

local function get_rose_pine_config()
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

  local colorscheme = theme_config.theme_colorscheme or theme_config.colorscheme

  return {
    theme = colorscheme,
    transparent = true,
    term_colors = true,
    alt_bg = true,
    show_eob = false,
    favor_treesitter_hl = true,
    code_style = code_style,
  }
end

local function get_kanagawa_config()
  local c = theme_config.semanticColors
  local overrides = {}

  overrides.WinBar = { bg = "none", fg = c.foreground.primary }
  overrides.WinBarNC = { bg = "none", fg = c.foreground.subtle }
  overrides.NeoTreeWinSeparator = { bg = "none", fg = c.plugins.filetree.separator }
  overrides.NeoTreeVertSplit = { bg = "none", fg = c.plugins.filetree.separator }
  overrides.NeoTreeEndOfBuffer = { bg = "none", fg = "none" }
  overrides.DropBarMenuFloatBorder = { bg = "none", fg = c.plugins.window.border }
  overrides.WildMenu = { bg = c.background.secondary, fg = c.foreground.primary, bold = true }
  overrides.WilderWildmenuSelected =
    { bg = c.background.secondary, fg = c.foreground.primary, bold = true }
  overrides.WilderWildmenuSelectedAccent =
    { bg = c.background.secondary, fg = c.foreground.primary, bold = true }
  overrides.TelescopeSelection =
    { bg = c.plugins.telescope.selection_bg, fg = c.plugins.telescope.selection_fg, bold = true }
  overrides.Pmenu = { bg = c.plugins.completion.menu_bg, fg = c.foreground.primary }
  overrides.PmenuSel =
    { bg = c.plugins.completion.selection_bg, fg = c.plugins.completion.selection_fg, bold = true }

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

  local colorscheme = theme_config.theme_colorscheme or theme_config.colorscheme

  return {
    theme = colorscheme,
    transparent = true,
    term_colors = true,
    alt_bg = true,
    show_eob = false,
    favor_treesitter_hl = true,
    code_style = code_style,
    highlights = overrides,
  }
end

local function get_nightfox_config()
  local c = theme_config.semanticColors

  return {
    options = {
      compile_path = vim.fn.stdpath("cache") .. "/nightfox",
      compile_file_suffix = "_compiled",
      transparent = true,
      terminal_colors = true,
      dim_inactive = false,
      module_default = true,
      styles = get_common_styles(),
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
        Visual = { bg = c.ui.selection, bold = true },
        VisualNOS = { bg = c.ui.selection, bold = true },
        WildMenu = { bg = c.background.secondary, fg = c.accent.primary, bold = true },
        WilderWildmenuSelected = { bg = c.background.secondary, fg = c.accent.primary, bold = true },
        WilderWildmenuSelectedAccent = {
          bg = c.background.secondary,
          fg = c.accent.primary,
          bold = true,
        },
        PmenuSel = {
          bg = c.plugins.completion.selection_bg,
          fg = c.plugins.completion.selection_fg,
          bold = true,
        },
        TelescopeSelection = {
          bg = c.plugins.telescope.selection_bg,
          fg = c.plugins.telescope.selection_fg,
          bold = true,
        },
        Search = { bg = c.plugins.search.match_bg, fg = c.plugins.search.match_fg, bold = true },
        IncSearch = {
          bg = c.plugins.search.incremental_bg,
          fg = c.plugins.search.incremental_fg,
          bold = true,
        },
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

  overrides.CursorLineNr = { bg = "NONE", fg = c.ui.line_number_active, bold = true }
  overrides.LineNr = { bg = "NONE", fg = c.ui.line_number }

  overrides.DiffAdd = { bg = c.diff.add_bg }
  overrides.DiffChange = { bg = c.diff.change_bg }
  overrides.DiffDelete = { bg = c.diff.delete_bg }

  overrides.FloatBorder = { bg = "NONE", fg = c.syntax.comment }
  overrides.FloatTitle = { bg = "NONE", fg = c.accent.primary, bold = true }
  overrides.NormalFloat = { bg = "NONE", fg = c.foreground.primary }
  overrides.DropBarMenuFloatBorder = { bg = "NONE", fg = c.foreground.subtle }

  overrides.Search = { bg = c.plugins.search.match_bg, fg = c.plugins.search.match_fg, bold = true }
  overrides.IncSearch =
    { bg = c.plugins.search.incremental_bg, fg = c.plugins.search.incremental_fg, bold = true }

  overrides.Pmenu = { bg = "NONE", fg = c.foreground.primary }
  overrides.PmenuBorder = { bg = "NONE", fg = c.plugins.completion.border }
  overrides.PmenuSel =
    { bg = c.plugins.completion.selection_bg, fg = c.plugins.completion.selection_fg, bold = true }

  overrides.StatusLine = { bg = "NONE", fg = c.plugins.window.statusline_active }
  overrides.StatusLineNC = { bg = "NONE", fg = c.plugins.window.statusline_inactive }

  overrides.TelescopeBorder = { bg = "NONE", fg = c.plugins.telescope.border }
  overrides.TelescopeSelection =
    { bg = c.plugins.telescope.selection_bg, fg = c.plugins.telescope.selection_fg, bold = true }
  overrides.TelescopeTitle = { bg = "NONE", fg = c.plugins.telescope.title, bold = true }

  overrides.WildMenu = { bg = "NONE", fg = c.accent.primary, bold = true }
  overrides.WilderWildmenuAccent = { fg = c.accent.primary, bold = true }
  overrides.WilderWildmenuSelected = { bg = "NONE", fg = c.accent.primary, bold = true }
  overrides.WilderWildmenuSelectedAccent = { fg = c.accent.primary, bold = true }

  overrides.WinBar = { bg = "NONE", fg = c.plugins.window.winbar_active }
  overrides.WinBarNC = { bg = "NONE", fg = c.plugins.window.winbar_inactive }

  overrides.NeoTreeEndOfBuffer = { bg = "NONE", fg = "NONE" }
  overrides.NeoTreeVertSplit = { bg = "NONE", fg = c.plugins.filetree.separator }
  overrides.NeoTreeWinSeparator = { bg = "NONE", fg = c.plugins.filetree.separator }

  overrides.NeogitDiffContext = { bg = "NONE", fg = c.foreground.primary }
  overrides.NeogitDiffContextCursor = { bg = "NONE" }
  overrides.NeogitDiffContextHighlight = { bg = "NONE" }
  overrides.NeogitDiffAdd = { bg = c.diff.add_bg, fg = c.diff.add }
  overrides.NeogitDiffAddCursor = { bg = c.diff.add_bg }
  overrides.NeogitDiffAddHighlight = { bg = c.diff.add_bg }
  overrides.NeogitDiffDelete = { bg = c.diff.delete_bg, fg = c.diff.delete }
  overrides.NeogitDiffDeleteCursor = { bg = c.diff.delete_bg }
  overrides.NeogitDiffDeleteHighlight = { bg = c.diff.delete_bg }

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
    theme_config.plugin,
    name = theme_config.name,
    lazy = false,
    priority = 1000,
    config = setup_theme,
  },
}

return M
