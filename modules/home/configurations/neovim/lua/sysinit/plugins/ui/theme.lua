local json_loader = require("sysinit.utils.json_loader")

-- Theme metadata
local THEME_METADATA = {
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
  ["rose-pine"] = {
    plugin = "casedami/neomodern.nvim",
    setup = "neomodern",
    colorscheme = "roseprime",
  },
  everforest = {
    plugin = "sainnhe/everforest",
    setup = "everforest",
    colorscheme = "everforest",
  },
}

-- Syntax styles
local SYNTAX_STYLES = {
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

-- Theme-specific configs
local function get_catppuccin_config(theme_config)
  return {
    flavour = theme_config.variant,
    show_end_of_buffer = false,
    transparent_background = true,
    float = { transparent = true, solid = false },
    styles = SYNTAX_STYLES,
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

local function get_gruvbox_config(theme_config)
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

local function get_neomodern_config(theme_config)
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

local function get_everforest_config(theme_config)
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

-- Highlight generators
local function generate_gitsigns_highlights()
  return {
    GitSignsAdd = { link = "DiffAdd" },
    GitSignsChange = { link = "DiffChange" },
    GitSignsDelete = { link = "DiffDelete" },
    GitSignsAddInline = { link = "DiffAdd" },
    GitSignsChangeInline = { link = "DiffChange" },
    GitSignsDeleteInline = { link = "DiffDelete" },
    GitSignsAddPreview = { link = "DiffAdd" },
    GitSignsDeletePreview = { link = "DiffDelete" },
  }
end

local function generate_treesitter_highlights()
  return {
    ["@variable"] = { link = "Identifier" },
    ["@variable.builtin"] = { link = "Special" },
    ["@variable.parameter"] = { link = "Identifier" },
    ["@variable.member"] = { link = "Identifier" },
    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { link = "Special" },
    ["@module"] = { link = "Include" },
    ["@string"] = { link = "String" },
    ["@string.special.url"] = { link = "Underlined" },
    ["@character"] = { link = "Character" },
    ["@number"] = { link = "Number" },
    ["@boolean"] = { link = "Boolean" },
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { link = "Special" },
    ["@constructor"] = { link = "Typedef" },
    ["@keyword"] = { link = "Keyword" },
    ["@operator"] = { link = "Operator" },
    ["@punctuation.bracket"] = { link = "Delimiter" },
    ["@type"] = { link = "Type" },
    ["@type.builtin"] = { link = "Type" },
    ["@comment"] = { link = "Comment" },
    ["@label"] = { link = "Label" },
    ["@tag"] = { link = "Tag" },
    ["@markup.heading"] = { link = "Title" },
    ["@markup.raw"] = { link = "String" },
    ["@markup.link.label"] = { link = "Special" },
    ["@markup.list"] = { link = "Delimiter" },
  }
end

local function generate_diagnostic_highlights()
  return {
    DiagnosticError = { link = "ErrorMsg" },
    DiagnosticWarn = { link = "WarningMsg" },
    DiagnosticInfo = { link = "Identifier" },
    DiagnosticHint = { link = "Comment" },
    DiagnosticOk = { link = "Question" },
    DiagnosticSignError = { link = "DiagnosticError" },
    DiagnosticSignWarn = { link = "DiagnosticWarn" },
    DiagnosticSignInfo = { link = "DiagnosticInfo" },
    DiagnosticSignHint = { link = "DiagnosticHint" },
  }
end

local function generate_lsp_highlights()
  return {
    ["@lsp.type.class"] = { link = "Structure" },
    ["@lsp.type.decorator"] = { link = "Function" },
    ["@lsp.type.enum"] = { link = "Type" },
    ["@lsp.type.enumMember"] = { link = "Constant" },
    ["@lsp.type.function"] = { link = "Function" },
    ["@lsp.type.interface"] = { link = "Type" },
    ["@lsp.type.macro"] = { link = "Macro" },
    ["@lsp.type.method"] = { link = "Function" },
    ["@lsp.type.namespace"] = { link = "Include" },
    ["@lsp.type.parameter"] = { link = "Identifier" },
    ["@lsp.type.property"] = { link = "Identifier" },
    ["@lsp.type.struct"] = { link = "Structure" },
    ["@lsp.type.type"] = { link = "Type" },
    ["@lsp.type.variable"] = { link = "Identifier" },
    ["@lsp.mod.deprecated"] = { strikethrough = true },
  }
end

local function generate_transparency_highlights(transparency)
  local transparent_groups = {
    "Normal",
    "NormalFloat",
    "NormalNC",
    "LineNr",
    "FoldColumn",
    "CursorLine",
    "Pmenu",
    "StatusLine",
    "StatusLineNC",
    "WinSeparator",
    "TelescopeNormal",
    "TelescopeBorder",
    "NeoTreeNormal",
    "NeoTreeNormalNC",
  }

  local highlights = {}
  if transparency.opacity < 1 then
    for _, group in ipairs(transparent_groups) do
      highlights[group] = { bg = "none" }
    end
  end
  return highlights
end

-- Apply all highlight overrides
local function apply_highlights(theme_config)
  local highlights = {}

  -- Merge all highlight groups
  vim.tbl_deep_extend("force", highlights, generate_transparency_highlights(theme_config.transparency))
  vim.tbl_deep_extend("force", highlights, generate_gitsigns_highlights())
  vim.tbl_deep_extend("force", highlights, generate_treesitter_highlights())
  vim.tbl_deep_extend("force", highlights, generate_diagnostic_highlights())
  vim.tbl_deep_extend("force", highlights, generate_lsp_highlights())

  -- Manual plugin-specific overrides
  local manual_overrides = {
    -- Floats & Menus
    FloatBorder = { link = "Comment" },
    FloatTitle = { link = "Title" },
    NormalFloat = { link = "Normal" },
    Pmenu = { link = "Normal" },
    PmenuSel = { link = "Visual" },

    -- Windows & Status
    WinSeparator = { link = "VertSplit" },
    WinBar = { link = "StatusLine" },
    WinBarNC = { link = "StatusLineNC" },

    -- Diagnostics
    DiagnosticVirtualLinesError = { link = "DiagnosticError" },
    DiagnosticVirtualLinesWarn = { link = "DiagnosticWarn" },
    DiagnosticVirtualLinesInfo = { link = "DiagnosticInfo" },
    DiagnosticVirtualLinesHint = { link = "DiagnosticHint" },

    -- Git (Neogit)
    NeogitDiffAdd = { link = "DiffAdd" },
    NeogitDiffDelete = { link = "DiffDelete" },
    NeogitDiffContextHighlight = { link = "CursorLine" },

    -- Neo-tree
    NeoTreeNormal = { link = "Normal" },
    NeoTreeDirectoryIcon = { link = "Directory" },
    NeoTreeDirectoryName = { link = "Directory" },
    NeoTreeFileName = { link = "Normal" },
    NeoTreeCursorLine = { link = "CursorLine" },
    NeoTreeGitAdded = { link = "DiffAdd" },
    NeoTreeGitModified = { link = "DiffChange" },
    NeoTreeGitDeleted = { link = "DiffDelete" },
    NeoTreeIndentMarker = { link = "NonText" },
    NeoTreeExpander = { link = "Comment" },

    -- Wilder / Completion
    WilderSelected = { link = "PmenuSel" },
    WilderAccent = { link = "Keyword" },
  }

  vim.tbl_deep_extend("force", highlights, manual_overrides)

  -- Apply all highlights
  for name, hl in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

-- Main setup function
local function setup_theme()
  local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")
  local active_scheme = theme_config and theme_config.colorscheme
  local plugin_config = THEME_METADATA[active_scheme]

  -- Configure theme-specific settings
  if active_scheme == "catppuccin" then
    local config = get_catppuccin_config(theme_config)
    require("catppuccin").setup(config)
  elseif active_scheme == "gruvbox" then
    get_gruvbox_config(theme_config)
  elseif active_scheme == "rose-pine" then
    local config = get_neomodern_config(theme_config)
    require("neomodern").setup(config)
  elseif active_scheme == "everforest" then
    get_everforest_config(theme_config)
  end

  -- Apply colorscheme
  vim.cmd.colorscheme(plugin_config.colorscheme)

  -- Apply custom highlights
  apply_highlights(theme_config)

  -- Re-apply on colorscheme change
  vim.api.nvim_create_autocmd({ "ColorScheme", "CmdLineEnter" }, {
    pattern = plugin_config.colorscheme,
    callback = function()
      apply_highlights(theme_config)
    end,
  })
end

-- Build plugin spec
local function build_plugins()
  local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")
  local scheme = theme_config and theme_config.colorscheme
  local metadata = THEME_METADATA[scheme]

  return {
    {
      metadata.plugin,
      lazy = false,
      priority = 1000,
      config = setup_theme,
    },
  }
end

return build_plugins()
