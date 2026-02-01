-- Theme setup and comprehensive highlight configuration
-- This runs after all plugins are loaded

-- Only run if Nix-managed (stylix provides colors)
if vim.g.nix_hm_managed then
  -- Stylix generates a call to require('base16-colorscheme') but base16-nvim uses 'base16'
  -- Create a compatibility shim
  package.preload["base16-colorscheme"] = function()
    return require("base16")
  end
end

-- Get base16 colors after colorscheme is loaded
local function get_base16_colors()
  -- Access colors from base16-colorscheme after it's loaded
  local ok, colorscheme = pcall(require, "base16-colorscheme")
  if ok and colorscheme.colors then
    return colorscheme.colors
  end
  -- Fallback: return nil and let highlights use default colors
  return nil
end

-- Apply all highlight groups using base16 colors
local function apply_highlights()
  local colors = get_base16_colors()
  if not colors then
    return
  end

  -- Transparency highlights
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

  for _, group in ipairs(transparent_groups) do
    vim.api.nvim_set_hl(0, group, { bg = "NONE" })
  end

  -- Additional transparency for core groups
  vim.api.nvim_set_hl(0, "NonText", { bg = "NONE", ctermbg = "NONE" })

  -- Cursor highlights
  vim.api.nvim_set_hl(0, "Cursor", { bg = colors.base0D, fg = colors.base00 })
  vim.api.nvim_set_hl(0, "lCursor", { link = "Cursor" })
  vim.api.nvim_set_hl(0, "CursorIM", { link = "Cursor" })
  vim.api.nvim_set_hl(0, "TermCursor", { link = "Cursor" })
  vim.api.nvim_set_hl(0, "TermCursorNC", { bg = colors.base0D, fg = colors.base00 })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "CursorColumn", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "LineNr", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "LineNrAbove", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "LineNrBelow", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "Visual", { bg = colors.base02, fg = colors.base05, bold = true })
  vim.api.nvim_set_hl(0, "VisualNOS", { bg = colors.base02, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "Search", { bg = colors.base0A, fg = colors.base00, bold = true })
  vim.api.nvim_set_hl(0, "IncSearch", { bg = colors.base08, fg = colors.base00, bold = true })
  vim.api.nvim_set_hl(0, "CurSearch", { link = "IncSearch" })
  vim.api.nvim_set_hl(0, "MatchParen", { bg = colors.base02, fg = colors.base0D, bold = true })

  -- Menu highlights
  vim.api.nvim_set_hl(0, "PmenuSel", { bg = "NONE", fg = colors.base0D, bold = true })

  -- Diff highlights
  vim.api.nvim_set_hl(0, "DiffAdd", { bg = colors.base01, fg = colors.base0B })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = colors.base01, fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = colors.base01, fg = colors.base08 })

  -- GitSigns highlights
  vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = colors.base0B, bold = true })
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "GitSignsAddInline", { bg = colors.base01, fg = colors.base0B })
  vim.api.nvim_set_hl(0, "GitSignsChangeInline", { bg = colors.base01, fg = colors.base0A })
  vim.api.nvim_set_hl(0, "GitSignsDeleteInline", { bg = colors.base01, fg = colors.base08 })
  vim.api.nvim_set_hl(0, "GitSignsAddLn", { bg = colors.base01 })
  vim.api.nvim_set_hl(0, "GitSignsChangeLn", { bg = colors.base01 })
  vim.api.nvim_set_hl(0, "GitSignsDeleteLn", { bg = colors.base01 })
  vim.api.nvim_set_hl(0, "GitSignsAddPreview", { link = "DiffAdd" })
  vim.api.nvim_set_hl(0, "GitSignsDeletePreview", { link = "DiffDelete" })

  -- Treesitter highlights using base16 colors
  vim.api.nvim_set_hl(0, "@variable", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "@variable.builtin", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "@variable.parameter", { fg = colors.base08, italic = true })
  vim.api.nvim_set_hl(0, "@variable.member", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "@constant", { fg = colors.base09 })
  vim.api.nvim_set_hl(0, "@constant.builtin", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "@constant.macro", { fg = colors.base09, bold = true })
  vim.api.nvim_set_hl(0, "@module", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "@module.builtin", { fg = colors.base0C })
  vim.api.nvim_set_hl(0, "@string", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "@string.escape", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "@string.special", { fg = colors.base0B, italic = true })
  vim.api.nvim_set_hl(0, "@string.special.symbol", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "@string.special.url", { fg = colors.base0C, underline = true })
  vim.api.nvim_set_hl(0, "@character", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "@character.special", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "@number", { fg = colors.base09, bold = true })
  vim.api.nvim_set_hl(0, "@number.float", { fg = colors.base09, bold = true })
  vim.api.nvim_set_hl(0, "@boolean", { fg = colors.base09, bold = true })
  vim.api.nvim_set_hl(0, "@function", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "@function.builtin", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "@function.call", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "@function.macro", { fg = colors.base0D, italic = true })
  vim.api.nvim_set_hl(0, "@function.method", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "@function.method.call", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "@constructor", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "@keyword", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "@keyword.conditional", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "@keyword.repeat", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "@keyword.return", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "@keyword.function", { fg = colors.base0E, italic = true })
  vim.api.nvim_set_hl(0, "@keyword.operator", { fg = colors.base05, bold = true })
  vim.api.nvim_set_hl(0, "@keyword.import", { fg = colors.base0E, italic = true })
  vim.api.nvim_set_hl(0, "@keyword.storage", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "@keyword.modifier", { fg = colors.base0E, italic = true })
  vim.api.nvim_set_hl(0, "@keyword.type", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "@keyword.coroutine", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "@keyword.debug", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "@keyword.exception", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "@operator", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "@punctuation.delimiter", { fg = colors.base04 })
  vim.api.nvim_set_hl(0, "@punctuation.bracket", { fg = colors.base04 })
  vim.api.nvim_set_hl(0, "@punctuation.special", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "@type", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "@type.builtin", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "@type.definition", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "@type.qualifier", { fg = colors.base0E, italic = true })
  vim.api.nvim_set_hl(0, "@attribute", { fg = colors.base0A, italic = true })
  vim.api.nvim_set_hl(0, "@attribute.builtin", { fg = colors.base0C, italic = true })
  vim.api.nvim_set_hl(0, "@property", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "@comment", { fg = colors.base03, italic = true })
  vim.api.nvim_set_hl(0, "@comment.documentation", { fg = colors.base03, italic = true })
  vim.api.nvim_set_hl(0, "@comment.error", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "@comment.warning", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "@comment.todo", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "@comment.note", { fg = colors.base0D, italic = true })
  vim.api.nvim_set_hl(0, "@label", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "@tag", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "@tag.attribute", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "@tag.delimiter", { fg = colors.base04 })
  vim.api.nvim_set_hl(0, "@markup.strong", { bold = true })
  vim.api.nvim_set_hl(0, "@markup.italic", { italic = true })
  vim.api.nvim_set_hl(0, "@markup.strikethrough", { strikethrough = true })
  vim.api.nvim_set_hl(0, "@markup.underline", { underline = true })
  vim.api.nvim_set_hl(0, "@markup.heading", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "@markup.heading.1", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "@markup.heading.2", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "@markup.heading.3", { fg = colors.base0B, bold = true })
  vim.api.nvim_set_hl(0, "@markup.heading.4", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "@markup.heading.5", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "@markup.heading.6", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "@markup.quote", { fg = colors.base03, italic = true })
  vim.api.nvim_set_hl(0, "@markup.math", { fg = colors.base09 })
  vim.api.nvim_set_hl(0, "@markup.link", { fg = colors.base0C, underline = true })
  vim.api.nvim_set_hl(0, "@markup.link.label", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "@markup.link.url", { fg = colors.base0C, underline = true })
  vim.api.nvim_set_hl(0, "@markup.raw", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "@markup.raw.block", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "@markup.list", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "@markup.list.checked", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "@markup.list.unchecked", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "@diff.plus", { link = "DiffAdd" })
  vim.api.nvim_set_hl(0, "@diff.minus", { link = "DiffDelete" })
  vim.api.nvim_set_hl(0, "@diff.delta", { link = "DiffChange" })

  -- Diagnostic highlights
  vim.api.nvim_set_hl(0, "DiagnosticError", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticOk", { fg = colors.base0B, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { sp = colors.base08, underline = true })
  vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { sp = colors.base0A, underline = true })
  vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { sp = colors.base0D, underline = true })
  vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { sp = colors.base0C, underline = true })
  vim.api.nvim_set_hl(0, "DiagnosticUnderlineOk", { sp = colors.base0B, underline = true })
  vim.api.nvim_set_hl(0, "DiagnosticSignError", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticSignWarn", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticSignInfo", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticSignHint", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticSignOk", { fg = colors.base0B, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticDeprecated", { fg = colors.base03, strikethrough = true })
  vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = colors.base03, italic = true })

  -- LSP highlights
  vim.api.nvim_set_hl(0, "@lsp.type.class", { link = "@type" })
  vim.api.nvim_set_hl(0, "@lsp.type.decorator", { link = "@function" })
  vim.api.nvim_set_hl(0, "@lsp.type.enum", { link = "@type" })
  vim.api.nvim_set_hl(0, "@lsp.type.enumMember", { link = "@constant" })
  vim.api.nvim_set_hl(0, "@lsp.type.function", { link = "@function" })
  vim.api.nvim_set_hl(0, "@lsp.type.interface", { link = "@type" })
  vim.api.nvim_set_hl(0, "@lsp.type.macro", { link = "@macro" })
  vim.api.nvim_set_hl(0, "@lsp.type.method", { link = "@method" })
  vim.api.nvim_set_hl(0, "@lsp.type.namespace", { link = "@namespace" })
  vim.api.nvim_set_hl(0, "@lsp.type.parameter", { link = "@parameter" })
  vim.api.nvim_set_hl(0, "@lsp.type.property", { link = "@property" })
  vim.api.nvim_set_hl(0, "@lsp.type.struct", { link = "@structure" })
  vim.api.nvim_set_hl(0, "@lsp.type.type", { link = "@type" })
  vim.api.nvim_set_hl(0, "@lsp.type.typeParameter", { link = "@type.definition" })
  vim.api.nvim_set_hl(0, "@lsp.type.variable", { link = "@variable" })
  vim.api.nvim_set_hl(0, "@lsp.mod.readonly", { fg = colors.base09, italic = true })
  vim.api.nvim_set_hl(0, "@lsp.mod.deprecated", { fg = colors.base03, strikethrough = true })
  vim.api.nvim_set_hl(0, "@lsp.mod.static", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "@lsp.mod.abstract", { italic = true })
  vim.api.nvim_set_hl(0, "@lsp.typemod.function.defaultLibrary", { link = "@function.builtin" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.variable.defaultLibrary", { link = "@variable.builtin" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly", { fg = colors.base09 })
end

-- Apply on startup (with delay to ensure colorscheme is loaded)
vim.defer_fn(apply_highlights, 100)

-- Reapply after colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.defer_fn(apply_highlights, 50)
  end,
  desc = "Reapply custom highlights after colorscheme change",
})
