-- Highlight Generator Utility
-- Generates comprehensive highlight groups from Nix-provided semantic colors
-- Themes can use this helper to reduce boilerplate while maintaining customization flexibility

local M = {}

-- Generate cursor and selection highlight groups
function M.generate_cursor_highlights(colors)
  return {
    -- Cursor
    Cursor = { bg = colors.ui.cursor, fg = colors.background.primary },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    TermCursor = { link = "Cursor" },
    TermCursorNC = { bg = colors.ui.cursor, fg = colors.background.primary },

    -- Cursor Line/Column
    CursorLine = { bg = colors.ui.cursor_line },
    CursorColumn = { bg = colors.ui.cursor_line },
    CursorLineNr = { fg = colors.ui.line_number_active, bold = true },
    CursorLineFold = { link = "FoldColumn" },
    CursorLineSign = { link = "SignColumn" },

    -- Line Numbers
    LineNr = { fg = colors.ui.line_number },
    LineNrAbove = { fg = colors.ui.line_number },
    LineNrBelow = { fg = colors.ui.line_number },

    -- Visual Mode
    Visual = { bg = colors.ui.visual_selection, fg = colors.foreground.primary, bold = true },
    VisualNOS = { bg = colors.ui.visual_selection, fg = colors.foreground.primary },

    -- Search
    Search = { bg = colors.semantic.warning, fg = colors.background.primary, bold = true },
    IncSearch = { bg = colors.semantic.error, fg = colors.background.primary, bold = true },
    CurSearch = { link = "IncSearch" },

    -- Matching
    MatchParen = { bg = colors.ui.match_paren, fg = colors.background.primary, bold = true },
  }
end

-- Generate Git diff highlight groups
function M.generate_diff_highlights(colors)
  return {
    DiffAdd = { bg = colors.diff.add_bg, fg = colors.diff.add },
    DiffChange = { bg = colors.diff.change_bg, fg = colors.diff.change },
    DiffDelete = { bg = colors.diff.delete_bg, fg = colors.diff.delete },
    DiffText = { bg = colors.diff.text, fg = colors.background.primary, bold = true },
  }
end

-- Generate essential Treesitter syntax highlight groups
function M.generate_treesitter_highlights(colors)
  return {
    -- Variables
    ["@variable"] = { fg = colors.syntax.variable },
    ["@variable.builtin"] = { fg = colors.syntax.builtin, bold = true },
    ["@variable.parameter"] = { fg = colors.syntax.variable, italic = true },
    ["@variable.member"] = { fg = colors.syntax.variable },

    -- Constants
    ["@constant"] = { fg = colors.syntax.constant },
    ["@constant.builtin"] = { fg = colors.syntax.builtin, bold = true },
    ["@constant.macro"] = { fg = colors.syntax.constant, bold = true },

    -- Modules/Namespaces
    ["@module"] = { fg = colors.syntax.type },
    ["@module.builtin"] = { fg = colors.syntax.builtin },

    -- Strings & Characters
    ["@string"] = { fg = colors.syntax.string },
    ["@string.escape"] = { fg = colors.syntax.operator, bold = true },
    ["@string.special"] = { fg = colors.syntax.string, italic = true },
    ["@string.special.symbol"] = { fg = colors.syntax.operator },
    ["@string.special.url"] = { fg = colors.accent.secondary, underline = true },
    ["@character"] = { fg = colors.syntax.string },
    ["@character.special"] = { fg = colors.syntax.operator },

    -- Numbers & Booleans
    ["@number"] = { fg = colors.syntax.number, bold = true },
    ["@number.float"] = { fg = colors.syntax.number, bold = true },
    ["@boolean"] = { fg = colors.syntax.constant, bold = true },

    -- Functions
    ["@function"] = { fg = colors.syntax["function"], bold = true },
    ["@function.builtin"] = { fg = colors.syntax.builtin, bold = true },
    ["@function.call"] = { fg = colors.syntax["function"] },
    ["@function.macro"] = { fg = colors.syntax["function"], italic = true },
    ["@function.method"] = { fg = colors.syntax["function"] },
    ["@function.method.call"] = { fg = colors.syntax["function"] },

    -- Constructors
    ["@constructor"] = { fg = colors.syntax.type, bold = true },

    -- Keywords
    ["@keyword"] = { fg = colors.syntax.keyword, bold = true },
    ["@keyword.conditional"] = { fg = colors.syntax.keyword, bold = true },
    ["@keyword.repeat"] = { fg = colors.syntax.keyword, bold = true },
    ["@keyword.return"] = { fg = colors.syntax.keyword, bold = true },
    ["@keyword.function"] = { fg = colors.syntax.keyword, italic = true },
    ["@keyword.operator"] = { fg = colors.syntax.operator, bold = true },
    ["@keyword.import"] = { fg = colors.syntax.keyword, italic = true },
    ["@keyword.storage"] = { fg = colors.syntax.keyword },
    ["@keyword.modifier"] = { fg = colors.syntax.keyword, italic = true },
    ["@keyword.type"] = { fg = colors.syntax.keyword },
    ["@keyword.coroutine"] = { fg = colors.syntax.keyword },
    ["@keyword.debug"] = { fg = colors.semantic.error },
    ["@keyword.exception"] = { fg = colors.semantic.error, bold = true },

    -- Operators & Punctuation
    ["@operator"] = { fg = colors.syntax.operator },
    ["@punctuation.delimiter"] = { fg = colors.foreground.secondary },
    ["@punctuation.bracket"] = { fg = colors.foreground.secondary },
    ["@punctuation.special"] = { fg = colors.syntax.operator },

    -- Types
    ["@type"] = { fg = colors.syntax.type, bold = true },
    ["@type.builtin"] = { fg = colors.syntax.builtin, bold = true },
    ["@type.definition"] = { fg = colors.syntax.type },
    ["@type.qualifier"] = { fg = colors.syntax.keyword, italic = true },

    -- Attributes/Properties
    ["@attribute"] = { fg = colors.syntax.type, italic = true },
    ["@attribute.builtin"] = { fg = colors.syntax.builtin, italic = true },
    ["@property"] = { fg = colors.syntax.variable },

    -- Comments & Documentation
    ["@comment"] = { fg = colors.syntax.comment, italic = true },
    ["@comment.documentation"] = { fg = colors.syntax.comment, italic = true },
    ["@comment.error"] = { fg = colors.semantic.error, bold = true },
    ["@comment.warning"] = { fg = colors.semantic.warning, bold = true },
    ["@comment.todo"] = { fg = colors.semantic.info, bold = true },
    ["@comment.note"] = { fg = colors.semantic.info, italic = true },

    -- Labels & Tags
    ["@label"] = { fg = colors.accent.primary },
    ["@tag"] = { fg = colors.syntax.keyword },
    ["@tag.attribute"] = { fg = colors.syntax.type },
    ["@tag.delimiter"] = { fg = colors.foreground.secondary },

    -- Markup (Markdown, etc.)
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.heading"] = { fg = colors.accent.primary, bold = true },
    ["@markup.heading.1"] = { fg = colors.semantic.error, bold = true },
    ["@markup.heading.2"] = { fg = colors.semantic.warning, bold = true },
    ["@markup.heading.3"] = { fg = colors.semantic.success, bold = true },
    ["@markup.heading.4"] = { fg = colors.semantic.info, bold = true },
    ["@markup.heading.5"] = { fg = colors.accent.primary, bold = true },
    ["@markup.heading.6"] = { fg = colors.accent.secondary, bold = true },
    ["@markup.quote"] = { fg = colors.foreground.muted, italic = true },
    ["@markup.math"] = { fg = colors.syntax.number },
    ["@markup.link"] = { fg = colors.accent.secondary, underline = true },
    ["@markup.link.label"] = { fg = colors.accent.primary },
    ["@markup.link.url"] = { fg = colors.accent.secondary, underline = true },
    ["@markup.raw"] = { fg = colors.syntax.string },
    ["@markup.raw.block"] = { fg = colors.syntax.string },
    ["@markup.list"] = { fg = colors.accent.primary },
    ["@markup.list.checked"] = { fg = colors.semantic.success },
    ["@markup.list.unchecked"] = { fg = colors.foreground.muted },

    -- Diff highlighting for Treesitter
    ["@diff.plus"] = { link = "DiffAdd" },
    ["@diff.minus"] = { link = "DiffDelete" },
    ["@diff.delta"] = { link = "DiffChange" },
  }
end

-- Generate diagnostic highlight groups
function M.generate_diagnostic_highlights(colors, transparency)
  local highlights = {
    -- Diagnostic text
    DiagnosticError = { fg = colors.semantic.error, bold = true },
    DiagnosticWarn = { fg = colors.semantic.warning, bold = true },
    DiagnosticInfo = { fg = colors.semantic.info, bold = true },
    DiagnosticHint = { fg = colors.accent.secondary, bold = true },
    DiagnosticOk = { fg = colors.semantic.success, bold = true },

    -- Diagnostic underlines
    DiagnosticUnderlineError = { sp = colors.semantic.error, underline = true },
    DiagnosticUnderlineWarn = { sp = colors.semantic.warning, underline = true },
    DiagnosticUnderlineInfo = { sp = colors.semantic.info, underline = true },
    DiagnosticUnderlineHint = { sp = colors.accent.secondary, underline = true },
    DiagnosticUnderlineOk = { sp = colors.semantic.success, underline = true },

    -- Diagnostic signs
    DiagnosticSignError = { fg = colors.semantic.error, bold = true },
    DiagnosticSignWarn = { fg = colors.semantic.warning, bold = true },
    DiagnosticSignInfo = { fg = colors.semantic.info, bold = true },
    DiagnosticSignHint = { fg = colors.accent.secondary, bold = true },
    DiagnosticSignOk = { fg = colors.semantic.success, bold = true },

    -- Special styles
    DiagnosticDeprecated = { fg = colors.foreground.muted, strikethrough = true },
    DiagnosticUnnecessary = { fg = colors.foreground.muted, italic = true },
  }

  -- Add virtual text highlights (respect transparency)
  if not transparency.enable then
    highlights.DiagnosticVirtualTextError = { fg = colors.semantic.error }
    highlights.DiagnosticVirtualTextWarn = { fg = colors.semantic.warning }
    highlights.DiagnosticVirtualTextInfo = { fg = colors.semantic.info }
    highlights.DiagnosticVirtualTextHint = { fg = colors.accent.secondary }
    highlights.DiagnosticVirtualTextOk = { fg = colors.semantic.success }
  end

  return highlights
end

-- Generate transparency overrides for plugins and UI elements
function M.generate_transparency_highlights(transparency)
  if not transparency.enable then
    return {}
  end

  -- List of all groups that should have transparent backgrounds
  local transparent_groups = {
    -- Completion
    "BlinkCmpDoc",
    "BlinkCmpDocBorder",
    "BlinkCmpMenu",
    "BlinkCmpMenuBorder",
    "BlinkCmpSignatureHelp",
    "BlinkCmpSignatureHelpBorder",
    -- Core UI
    "ColorColumn",
    "CursorColumn",
    "CursorLine",
    "CursorLineFold",
    "CursorLineNr",
    "CursorLineSign",
    -- Diagnostics
    "DiagnosticVirtualTextError",
    "DiagnosticVirtualTextHint",
    "DiagnosticVirtualTextInfo",
    "DiagnosticVirtualTextWarn",
    -- Dropbar
    "DropBarCurrentContext",
    "DropBarIconKindDefault",
    "DropBarIconKindDefaultNC",
    "DropBarMenuFloatBorder",
    "DropBarMenuNormalFloat",
    -- Edgy
    "EdgyIcon",
    "EdgyIconActive",
    "EdgyTitle",
    -- Floats
    "FloatBorder",
    "FloatTitle",
    "FoldColumn",
    -- Git Signs
    "GitSignsAdd",
    "GitSignsAddCul",
    "GitSignsChange",
    "GitSignsChangeCul",
    "GitSignsDelete",
    "GitSignsDeleteCul",
    -- Lazy
    "LazyNormal",
    -- Line numbers
    "LineNr",
    "LineNrAbove",
    "LineNrBelow",
    -- Messages
    "MsgSeparator",
    -- NeoTree
    "NeoTreeEndOfBuffer",
    "NeoTreeNormal",
    "NeoTreeNormalNC",
    "NeoTreeVertSplit",
    "NeoTreeWinSeparator",
    -- Normal
    "Normal",
    "NormalFloat",
    "NormalNC",
    -- Popup menu
    "Pmenu",
    "PmenuBorder",
    "PmenuSbar",
    "PmenuThumb",
    -- Sign column
    "SignColumn",
    -- Status line
    "StatusLine",
    "StatusLineNC",
    "StatusLineTerm",
    "StatusLineTermNC",
    -- Tabs
    "TabLine",
    "TabLineFill",
    -- Telescope
    "TelescopeBorder",
    "TelescopeNormal",
    "TelescopeSelection",
    -- Treesitter
    "TreesitterContext",
    "TreesitterContextLineNumber",
    -- Which-key
    "WhichKeyBorder",
    "WhichKeyFloat",
    -- Window
    "WinBar",
    "WinBarNC",
    "WinSeparator",
  }

  local highlights = {}
  for _, group in ipairs(transparent_groups) do
    highlights[group] = { bg = "none" }
  end

  return highlights
end

-- Generate LSP semantic token highlights
function M.generate_lsp_highlights(colors)
  return {
    -- LSP type highlights
    ["@lsp.type.class"] = { link = "@type" },
    ["@lsp.type.decorator"] = { link = "@function" },
    ["@lsp.type.enum"] = { link = "@type" },
    ["@lsp.type.enumMember"] = { link = "@constant" },
    ["@lsp.type.function"] = { link = "@function" },
    ["@lsp.type.interface"] = { link = "@type" },
    ["@lsp.type.macro"] = { link = "@macro" },
    ["@lsp.type.method"] = { link = "@method" },
    ["@lsp.type.namespace"] = { link = "@namespace" },
    ["@lsp.type.parameter"] = { link = "@parameter" },
    ["@lsp.type.property"] = { link = "@property" },
    ["@lsp.type.struct"] = { link = "@structure" },
    ["@lsp.type.type"] = { link = "@type" },
    ["@lsp.type.typeParameter"] = { link = "@type.definition" },
    ["@lsp.type.variable"] = { link = "@variable" },

    -- LSP modifier highlights
    ["@lsp.mod.readonly"] = { fg = colors.syntax.constant, italic = true },
    ["@lsp.mod.deprecated"] = { fg = colors.foreground.muted, strikethrough = true },
    ["@lsp.mod.static"] = { fg = colors.syntax.keyword, bold = true },
    ["@lsp.mod.abstract"] = { italic = true },

    -- Combined type + modifier
    ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
    ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
    ["@lsp.typemod.variable.readonly"] = { fg = colors.syntax.constant },
  }
end

-- Get all core highlights in one call
function M.generate_core_highlights(colors, palette, transparency)
  return vim.tbl_extend(
    "force",
    M.generate_transparency_highlights(transparency),
    M.generate_cursor_highlights(colors),
    M.generate_diff_highlights(colors),
    M.generate_treesitter_highlights(colors),
    M.generate_diagnostic_highlights(colors, transparency),
    M.generate_lsp_highlights(colors)
  )
end

-- Apply highlight groups
function M.apply_highlights(highlights)
  for name, hl in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

return M
