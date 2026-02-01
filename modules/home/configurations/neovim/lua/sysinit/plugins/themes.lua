local json_loader = require("sysinit.utils.json_loader")

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

local TRANSPARENT_GROUPS = {
  "BlinkCmpDoc",
  "BlinkCmpDocBorder",
  "BlinkCmpMenu",
  "BlinkCmpMenuBorder",
  "BlinkCmpSignatureHelp",
  "BlinkCmpSignatureHelpBorder",
  "ColorColumn",
  "CursorColumn",
  "CursorLine",
  "CursorLineFold",
  "CursorLineNr",
  "CursorLineSign",
  "DiagnosticVirtualTextError",
  "DiagnosticVirtualTextHint",
  "DiagnosticVirtualTextInfo",
  "DiagnosticVirtualTextWarn",
  "DropBarCurrentContext",
  "DropBarIconKindDefault",
  "DropBarIconKindDefaultNC",
  "DropBarMenuFloatBorder",
  "DropBarMenuNormalFloat",
  "FloatBorder",
  "FloatTitle",
  "FoldColumn",
  "GitSignsAddLnInline",
  "GitSignsAddPreview",
  "GitSignsChangeLnInline",
  "GitSignsDeleteLnInline",
  "GitSignsDeletePreview",
  "GitSignsDeleteVirtLn",
  "GitSignsStagedAdd",
  "GitSignsStagedAddCul",
  "GitSignsStagedAddLn",
  "GitSignsStagedAddNr",
  "GitSignsStagedChange",
  "GitSignsStagedChangeCul",
  "GitSignsStagedChangeLn",
  "GitSignsStagedChangeNr",
  "GitSignsStagedDelete",
  "GitSignsStagedDeleteCul",
  "GitSignsStagedDeleteLn",
  "GitSignsStagedDeleteNr",
  "GitSignsStagedTopdelete",
  "GitSignsStagedTopdeleteCul",
  "GitSignsStagedTopdeleteNr",
  "GitSignsStagedUntracked",
  "GitSignsStagedUntrackedCul",
  "GitSignsStagedUntrackedLn",
  "GitSignsStagedUntrackedNr",
  "GitSignsVirtLnum",
  "LazyNormal",
  "LineNr",
  "LineNrAbove",
  "LineNrBelow",
  "MsgSeparator",
  "NeoTreeGitAdded",
  "NeoTreeGitDeleted",
  "NeoTreeGitModified",
  "NeoTreeGitRenamed",
  "Normal",
  "NormalFloat",
  "NormalNC",
  "Pmenu",
  "PmenuBorder",
  "PmenuSbar",
  "PmenuThumb",
  "SignColumn",
  "StatusLine",
  "StatusLineNC",
  "StatusLineTerm",
  "StatusLineTermNC",
  "TabLine",
  "TabLineFill",
  "TreesitterContext",
  "TreesitterContextLineNumber",
  "WhichKeyBorder",
  "WhichKeyFloat",
  "WilderGradient1",
  "WilderGradient2",
  "WilderGradient3",
  "WilderGradient4",
  "WilderSeparator",
  "WilderSpinner",
  "WinBar",
  "WinBarNC",
  "WinSeparator",
}

local HIGHLIGHT_OVERRIDES = {
  DiagnosticError = { link = "ErrorMsg" },
  DiagnosticHint = { link = "Comment" },
  DiagnosticInfo = { link = "Identifier" },
  DiagnosticOk = { link = "Question" },
  DiagnosticWarn = { link = "WarningMsg" },
  ["@constant.builtin"] = { link = "Special" },
  ["@constructor"] = { link = "Typedef" },
  ["@function.builtin"] = { link = "Special" },
  ["@markup.heading"] = { link = "Title" },
  ["@markup.link.label"] = { link = "Special" },
  ["@markup.raw"] = { link = "String" },
  ["@module"] = { link = "Include" },
  ["@string.special.url"] = { link = "Underlined" },
  ["@variable"] = { link = "Identifier" },
  ["@variable.builtin"] = { link = "Special" },
  ["@variable.member"] = { link = "Identifier" },
  ["@variable.parameter"] = { link = "Identifier" },
}

local THEMES = {
  catppuccin = {
    plugin = "catppuccin/nvim",
    colorscheme = "catppuccin",
    setup = function(cfg)
      require("catppuccin").setup({
        flavour = cfg.variant or "mocha",
        show_end_of_buffer = false,
        transparent_background = true,
        float = { transparent = true, solid = false },
        styles = SYNTAX_STYLES,
        integrations = {
          cmp = true,
          dap = true,
          dap_ui = true,
          fzf = true,
          gitsigns = true,
          grug_far = true,
          hop = true,
          notify = true,
          nvimtree = true,
          markview = true,
          semantic_tokens = true,
          treesitter = true,
          treesitter_context = true,
          which_key = true,
          snacks = { enabled = true },
          telescope = { enabled = true, style = "nvchad" },
          dropbar = { enabled = true, color_mode = true },
          indent_blankline = { enabled = true, scope_color = "lavender", colored_indent_levels = true },
          native_lsp = { enabled = true, virtual_text = { errors = { "italic" }, hints = { "italic" } } },
        },
      })
    end,
  },

  gruvbox = {
    plugin = "sainnhe/gruvbox-material",
    colorscheme = "gruvbox-material",
    setup = function(cfg)
      local bg = vim.tbl_contains({ "hard", "medium", "soft" }, cfg.variant) and cfg.variant or "medium"
      vim.g.gruvbox_material_background = bg
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_disable_italic_comment = 0
      vim.g.gruvbox_material_transparent_background = 2
      vim.g.gruvbox_material_sign_column_background = "none"
      vim.g.gruvbox_material_ui_contrast = "low"
      vim.g.gruvbox_material_show_eob = 0
      vim.g.gruvbox_material_float_style = "bright"
      vim.g.gruvbox_material_diagnostic_virtual_text = "grey"
      vim.g.gruvbox_material_current_word = "bold"
      vim.g.gruvbox_material_inlay_hints_background = "dimmed"
    end,
  },

  ["rose-pine"] = {
    plugin = "casedami/neomodern.nvim",
    colorscheme = "roseprime",
    setup = function(cfg)
      require("neomodern").setup({
        theme = cfg.colorscheme or "roseprime",
        transparent = true,
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
      })
    end,
  },

  everforest = {
    plugin = "sainnhe/everforest",
    colorscheme = "everforest",
    setup = function(cfg)
      local bg = "medium"
      if cfg.variant then
        local p = vim.split(cfg.variant, "-")[2]
        if vim.tbl_contains({ "hard", "medium", "soft" }, p) then
          bg = p
        end
      end
      vim.g.everforest_background = bg
      vim.g.everforest_better_performance = 1
      vim.g.everforest_enable_italic = 1
      vim.g.everforest_disable_italic_comment = 0
      vim.g.everforest_transparent_background = 2
      vim.g.everforest_sign_column_background = "none"
      vim.g.everforest_ui_contrast = "low"
      vim.g.everforest_show_eob = 0
      vim.g.everforest_float_style = "bright"
      vim.g.everforest_diagnostic_virtual_text = "grey"
      vim.g.everforest_current_word = "bold"
      vim.g.everforest_inlay_hints_background = "dimmed"
    end,
  },
}

local function apply_highlights()
  local highlights = {}

  if vim.g.nix_managed == true then
    for _, group in ipairs(TRANSPARENT_GROUPS) do
      highlights[group] = { bg = "none" }
    end
  end

  for group, attrs in pairs(HIGHLIGHT_OVERRIDES) do
    highlights[group] = attrs
  end

  for name, val in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, val)
  end
end

local function setup_theme(meta, cfg)
  if meta.setup then
    meta.setup(cfg)
  end

  vim.cmd.colorscheme(meta.colorscheme)
  apply_highlights()

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    pattern = meta.colorscheme,
    callback = apply_highlights,
  })
end

local function get_theme_config()
  local config = {
    colorscheme = "miniautumn",
  }

  if vim.g.nix_managed then
    local loaded = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")
    if loaded then
      config = loaded
    end
  end

  return config
end

local active_cfg = get_theme_config()
local active_meta = THEMES[active_cfg.colorscheme] or { plugin = "nvim-mini/mini.base16" }

return {
  {
    active_meta.plugin,
    lazy = false,
    priority = 1000,
    config = function()
      if not vim.g.nix_managed then
        vim.cmd.colorscheme(active_meta.colorscheme)
        apply_highlights()
      else
        setup_theme(active_meta, active_cfg)
      end
    end,
  },
}
