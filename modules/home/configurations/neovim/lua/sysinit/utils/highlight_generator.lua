local M = {}

function M.generate_cursor_highlights(colors)
  return {
    Cursor = { bg = colors.ui.cursor, fg = colors.background.primary },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    TermCursor = { link = "Cursor" },
    TermCursorNC = { bg = colors.ui.cursor, fg = colors.background.primary },
    CursorLine = { bg = colors.ui.cursor_line },
    CursorColumn = { bg = colors.ui.cursor_line },
    CursorLineNr = { fg = colors.ui.line_number_active, bold = true },
    CursorLineFold = { link = "FoldColumn" },
    CursorLineSign = { link = "SignColumn" },
    LineNr = { fg = colors.ui.line_number },
    LineNrAbove = { fg = colors.ui.line_number },
    LineNrBelow = { fg = colors.ui.line_number },
    -- Muted cyan for visual selection - subtle and complementary
    Visual = { bg = colors.accent.secondary, bold = true },
    VisualNOS = { bg = colors.ui.visual_selection },
    Search = { bg = colors.semantic.warning, fg = colors.background.primary, bold = true },
    IncSearch = { bg = colors.semantic.error, fg = colors.background.primary, bold = true },
    CurSearch = { link = "IncSearch" },
    MatchParen = { bg = colors.ui.match_paren, fg = colors.background.primary, bold = true },
  }
end

function M.generate_menu_highlights(colors)
  return {
    WildMenu = { bg = "NONE", fg = colors.semantic.error, bold = true },

    PmenuSel = { bg = "NONE", fg = colors.accent.primary, bold = true },

    WilderWildmenuAccent = { fg = colors.semantic.error, bold = true },
    WilderWildmenuSelectedAccent = {
      bg = "NONE",
      fg = colors.semantic.error,
      bold = true,
    },
  }
end

function M.generate_diff_highlights(colors)
  return {
    -- Much starker diff highlighting with stronger backgrounds
    DiffAdd = { bg = colors.semantic.success, fg = colors.background.primary, bold = true },
    DiffChange = { bg = colors.semantic.warning, fg = colors.background.primary, bold = true },
    DiffDelete = { bg = colors.semantic.error, fg = colors.background.primary, bold = true },
    DiffText = { bg = colors.accent.primary, fg = colors.background.primary, bold = true, underline = true },
  }
end

function M.generate_gitsigns_highlights(colors)
  return {
    GitSignsAdd = { fg = colors.semantic.success, bold = true },
    GitSignsChange = { fg = colors.semantic.warning, bold = true },
    GitSignsDelete = { fg = colors.semantic.error, bold = true },
    -- Much starker inline diff highlighting
    GitSignsAddInline = { bg = colors.semantic.success, fg = colors.background.primary, bold = true },
    GitSignsChangeInline = { bg = colors.semantic.warning, fg = colors.background.primary, bold = true },
    GitSignsDeleteInline = { bg = colors.semantic.error, fg = colors.background.primary, bold = true },
    -- Stronger line backgrounds for changed lines
    GitSignsAddLn = { bg = colors.diff.add_bg },
    GitSignsChangeLn = { bg = colors.diff.change_bg },
    GitSignsDeleteLn = { bg = colors.diff.delete_bg },
    GitSignsAddPreview = { link = "DiffAdd" },
    GitSignsDeletePreview = { link = "DiffDelete" },
  }
end

function M.generate_telescope_highlights(colors)
  return {
    TelescopeNormal = { link = "Normal" },
    TelescopeBorder = { link = "FloatBorder" },
    TelescopeSelection = { fg = colors.semantic.error, bold = true },
    telescopeselectionCaret = { link = "pmenusel" },

    TelescopePromptNormal = { link = "Normal" },
    TelescopePromptBorder = { link = "FloatBorder" },
    TelescopePromptTitle = { link = "FloatTitle" },
    TelescopePromptPrefix = { fg = colors.accent.primary, bold = true },
    TelescopePromptCounter = { fg = colors.foreground.secondary },

    TelescopeResultsNormal = { link = "Normal" },
    TelescopeResultsBorder = { link = "FloatBorder" },
    TelescopeResultsTitle = { link = "FloatTitle" },
    TelescopeResultsLineNr = { link = "LineNr" },

    TelescopePreviewNormal = { link = "Normal" },
    TelescopePreviewBorder = { link = "FloatBorder" },
    TelescopePreviewTitle = { link = "FloatTitle" },
    TelescopePreviewLine = { bg = colors.ui.cursor_line },
    TelescopePreviewMatch = {
      bg = colors.semantic.warning,
      fg = colors.background.primary,
      bold = true,
    },
  }
end

function M.generate_treesitter_highlights(colors)
  return {
    ["@variable"] = { fg = colors.syntax.variable },
    ["@variable.builtin"] = { fg = colors.syntax.builtin, bold = true },
    ["@variable.parameter"] = { fg = colors.syntax.variable, italic = true },
    ["@variable.member"] = { fg = colors.syntax.variable },
    ["@constant"] = { fg = colors.syntax.constant },
    ["@constant.builtin"] = { fg = colors.syntax.builtin, bold = true },
    ["@constant.macro"] = { fg = colors.syntax.constant, bold = true },
    ["@module"] = { fg = colors.syntax.type },
    ["@module.builtin"] = { fg = colors.syntax.builtin },
    ["@string"] = { fg = colors.syntax.string },
    ["@string.escape"] = { fg = colors.syntax.operator, bold = true },
    ["@string.special"] = { fg = colors.syntax.string, italic = true },
    ["@string.special.symbol"] = { fg = colors.syntax.operator },
    ["@string.special.url"] = { fg = colors.accent.secondary, underline = true },
    ["@character"] = { fg = colors.syntax.string },
    ["@character.special"] = { fg = colors.syntax.operator },
    ["@number"] = { fg = colors.syntax.number, bold = true },
    ["@number.float"] = { fg = colors.syntax.number, bold = true },
    ["@boolean"] = { fg = colors.syntax.constant, bold = true },
    ["@function"] = { fg = colors.syntax["function"], bold = true },
    ["@function.builtin"] = { fg = colors.syntax.builtin, bold = true },
    ["@function.call"] = { fg = colors.syntax["function"] },
    ["@function.macro"] = { fg = colors.syntax["function"], italic = true },
    ["@function.method"] = { fg = colors.syntax["function"] },
    ["@function.method.call"] = { fg = colors.syntax["function"] },
    ["@constructor"] = { fg = colors.syntax.type, bold = true },
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
    ["@operator"] = { fg = colors.syntax.operator },
    ["@punctuation.delimiter"] = { fg = colors.foreground.secondary },
    ["@punctuation.bracket"] = { fg = colors.foreground.secondary },
    ["@punctuation.special"] = { fg = colors.syntax.operator },
    ["@type"] = { fg = colors.syntax.type, bold = true },
    ["@type.builtin"] = { fg = colors.syntax.builtin, bold = true },
    ["@type.definition"] = { fg = colors.syntax.type },
    ["@type.qualifier"] = { fg = colors.syntax.keyword, italic = true },
    ["@attribute"] = { fg = colors.syntax.type, italic = true },
    ["@attribute.builtin"] = { fg = colors.syntax.builtin, italic = true },
    ["@property"] = { fg = colors.syntax.variable },
    ["@comment"] = { fg = colors.syntax.comment, italic = true },
    ["@comment.documentation"] = { fg = colors.syntax.comment, italic = true },
    ["@comment.error"] = { fg = colors.semantic.error, bold = true },
    ["@comment.warning"] = { fg = colors.semantic.warning, bold = true },
    ["@comment.todo"] = { fg = colors.semantic.info, bold = true },
    ["@comment.note"] = { fg = colors.semantic.info, italic = true },
    ["@label"] = { fg = colors.accent.primary },
    ["@tag"] = { fg = colors.syntax.keyword },
    ["@tag.attribute"] = { fg = colors.syntax.type },
    ["@tag.delimiter"] = { fg = colors.foreground.secondary },
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
    ["@diff.plus"] = { link = "DiffAdd" },
    ["@diff.minus"] = { link = "DiffDelete" },
    ["@diff.delta"] = { link = "DiffChange" },
  }
end

function M.generate_diagnostic_highlights(colors, transparency)
  local highlights = {
    DiagnosticError = { fg = colors.semantic.error, bold = true },
    DiagnosticWarn = { fg = colors.semantic.warning, bold = true },
    DiagnosticInfo = { fg = colors.semantic.info, bold = true },
    DiagnosticHint = { fg = colors.accent.secondary, bold = true },
    DiagnosticOk = { fg = colors.semantic.success, bold = true },
    DiagnosticUnderlineError = { sp = colors.semantic.error, underline = true },
    DiagnosticUnderlineWarn = { sp = colors.semantic.warning, underline = true },
    DiagnosticUnderlineInfo = { sp = colors.semantic.info, underline = true },
    DiagnosticUnderlineHint = { sp = colors.accent.secondary, underline = true },
    DiagnosticUnderlineOk = { sp = colors.semantic.success, underline = true },
    DiagnosticSignError = { fg = colors.semantic.error, bold = true },
    DiagnosticSignWarn = { fg = colors.semantic.warning, bold = true },
    DiagnosticSignInfo = { fg = colors.semantic.info, bold = true },
    DiagnosticSignHint = { fg = colors.accent.secondary, bold = true },
    DiagnosticSignOk = { fg = colors.semantic.success, bold = true },
    DiagnosticDeprecated = { fg = colors.foreground.muted, strikethrough = true },
    DiagnosticUnnecessary = { fg = colors.foreground.muted, italic = true },
  }

  if not transparency.enable then
    highlights.DiagnosticVirtualTextError = { fg = colors.semantic.error }
    highlights.DiagnosticVirtualTextWarn = { fg = colors.semantic.warning }
    highlights.DiagnosticVirtualTextInfo = { fg = colors.semantic.info }
    highlights.DiagnosticVirtualTextHint = { fg = colors.accent.secondary }
    highlights.DiagnosticVirtualTextOk = { fg = colors.semantic.success }
  end

  return highlights
end

function M.generate_transparency_highlights(transparency)
  if not transparency.enable then
    return {}
  end

  local transparent_groups = {
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
    "EdgyIcon",
    "EdgyIconActive",
    "EdgyTitle",
    "FloatBorder",
    "FloatTitle",
    "FoldColumn",
    "GitSignsAdd",
    "GitSignsChange",
    "GitSignsDelete",
    "LazyNormal",
    "LineNr",
    "LineNrAbove",
    "LineNrBelow",
    "MsgSeparator",
    "NeoTreeEndOfBuffer",
    "NeoTreeNormal",
    "NeoTreeNormalNC",
    "NeoTreeVertSplit",
    "NeoTreeWinSeparator",
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
    "TelescopeBorder",
    "TelescopeNormal",
    "TelescopePromptBorder",
    "TelescopePromptNormal",
    "TelescopeResultsBorder",
    "TelescopeResultsNormal",
    "TelescopePreviewBorder",
    "TelescopePreviewNormal",
    "TelescopeSelection",
    "TreesitterContext",
    "TreesitterContextLineNumber",
    "WhichKeyBorder",
    "WhichKeyFloat",
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

function M.generate_lsp_highlights(colors)
  return {
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
    ["@lsp.mod.readonly"] = { fg = colors.syntax.constant, italic = true },
    ["@lsp.mod.deprecated"] = { fg = colors.foreground.muted, strikethrough = true },
    ["@lsp.mod.static"] = { fg = colors.syntax.keyword, bold = true },
    ["@lsp.mod.abstract"] = { italic = true },
    ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
    ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
    ["@lsp.typemod.variable.readonly"] = { fg = colors.syntax.constant },
  }
end

function M.generate_core_highlights(colors, transparency)
  return vim.tbl_extend(
    "force",
    M.generate_transparency_highlights(transparency),
    M.generate_cursor_highlights(colors),
    M.generate_menu_highlights(colors),
    M.generate_diff_highlights(colors),
    M.generate_gitsigns_highlights(colors),
    M.generate_telescope_highlights(colors),
    M.generate_treesitter_highlights(colors),
    M.generate_diagnostic_highlights(colors, transparency),
    M.generate_lsp_highlights(colors)
  )
end

function M.apply_highlights(highlights)
  for name, hl in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

return M
