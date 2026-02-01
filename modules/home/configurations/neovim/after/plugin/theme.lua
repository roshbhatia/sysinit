local function get_transparency_state()
  local state = vim.g.transparency_user_override
  if state == nil then
    state = vim.g.nix_transparency_enabled or false
  end
  return state
end

local function get_base16_colors()
  -- stylix generates base16-colorscheme module with setup() call and colors embedded
  local ok, colorscheme = pcall(require, "base16-colorscheme")
  if ok and colorscheme.colors then
    return colorscheme.colors
  end

  return nil
end

local function reload_base16_colorscheme()
  -- Reload base16 colorscheme by calling setup again
  local ok, colorscheme = pcall(require, "base16-colorscheme")
  if ok and colorscheme.setup then
    colorscheme.setup()
  end
end

local function apply_transparency()
  local trans_state = get_transparency_state()
  if not trans_state then
    -- If transparency is not enabled, do nothing silently
    return
  end

  local transparent_groups = {
    "Normal",
    "NormalNC",
    "NonText",
    "SignColumn",
    "LineNr",
    "LineNrAbove",
    "LineNrBelow",
    "CursorLineNr",
    "FoldColumn",
    "EndOfBuffer",
    "NormalFloat",
    "FloatBorder",
    "FloatTitle",
    "Pmenu",
    "PmenuBorder",
    "PmenuSbar",
    "PmenuThumb",
    "WilderMenu",
    "WilderBorder",
    "WilderAccent",
    "BlinkCmpDoc",
    "BlinkCmpDocBorder",
    "BlinkCmpMenu",
    "BlinkCmpMenuBorder",
    "BlinkCmpSignatureHelp",
    "BlinkCmpSignatureHelpBorder",
    "TelescopeBorder",
    "TelescopeNormal",
    "TelescopePromptBorder",
    "TelescopePromptNormal",
    "TelescopeResultsBorder",
    "TelescopeResultsNormal",
    "TelescopePreviewBorder",
    "TelescopePreviewNormal",
    "TelescopeSelection",
    "WhichKeyBorder",
    "WhichKeyFloat",
    "LazyNormal",
    "StatusLine",
    "StatusLineNC",
    "TabLine",
    "TabLineFill",
    "WinBar",
    "WinBarNC",
    "WinSeparator",
    "CursorLine",
    "CursorColumn",
    "ColorColumn",
  }

  for _, group in ipairs(transparent_groups) do
    -- Get existing highlight to preserve fg and other attributes
    local existing = vim.api.nvim_get_hl(0, { name = group, link = false })
    -- Create new highlight with transparent background
    -- Set bg to "NONE" string, and preserve all existing attributes except bg
    local new_hl = {}
    for key, value in pairs(existing) do
      if key ~= "bg" and key ~= "ctermbg" then
        new_hl[key] = value
      end
    end
    -- Explicitly set transparent background
    new_hl.bg = "NONE"
    vim.api.nvim_set_hl(0, group, new_hl)
  end
end

local function apply_highlights()
  local colors = get_base16_colors()
  if not colors then
    return
  end

  -- If transparency is enabled, ensure base groups don't have backgrounds
  local transparency_enabled = get_transparency_state()
  if transparency_enabled then
    for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat" }) do
      local existing = vim.api.nvim_get_hl(0, { name = group, link = false })
      local new_hl = {}
      for key, value in pairs(existing) do
        if key ~= "bg" and key ~= "ctermbg" then
          new_hl[key] = value
        end
      end
      new_hl.bg = "NONE"
      vim.api.nvim_set_hl(0, group, new_hl)
    end
  end

  vim.api.nvim_set_hl(0, "Cursor", { bg = colors.base0D, fg = colors.base00 })
  vim.api.nvim_set_hl(0, "lCursor", { link = "Cursor" })
  vim.api.nvim_set_hl(0, "CursorIM", { link = "Cursor" })
  vim.api.nvim_set_hl(0, "TermCursor", { link = "Cursor" })
  vim.api.nvim_set_hl(0, "TermCursorNC", { bg = colors.base0D, fg = colors.base00 })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = colors.base0D, bold = true, bg = "NONE" })
  vim.api.nvim_set_hl(0, "LineNr", { fg = colors.base03, bg = "NONE" })
  vim.api.nvim_set_hl(0, "LineNrAbove", { fg = colors.base03, bg = "NONE" })
  vim.api.nvim_set_hl(0, "LineNrBelow", { fg = colors.base03, bg = "NONE" })
  vim.api.nvim_set_hl(0, "Visual", { bg = colors.base02, fg = colors.base05, bold = true })
  vim.api.nvim_set_hl(0, "VisualNOS", { bg = colors.base02, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "Search", { bg = colors.base0A, fg = colors.base00, bold = true })
  vim.api.nvim_set_hl(0, "IncSearch", { bg = colors.base08, fg = colors.base00, bold = true })
  vim.api.nvim_set_hl(0, "CurSearch", { link = "IncSearch" })
  vim.api.nvim_set_hl(0, "MatchParen", { bg = colors.base02, fg = colors.base0D, bold = true })

  vim.api.nvim_set_hl(0, "PmenuSel", { bg = "NONE", fg = colors.base0D, bold = true })

  vim.api.nvim_set_hl(0, "DiffAdd", { bg = colors.base01, fg = colors.base0B })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = colors.base01, fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = colors.base01, fg = colors.base08 })
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

  -- Plugin integrations
  -- Blink CMP (completion)
  local bg_menu = transparency_enabled and "NONE" or colors.base01
  vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = bg_menu, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { bg = bg_menu, fg = colors.base03 })
  vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { bg = colors.base02, fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = bg_menu, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = bg_menu, fg = colors.base03 })
  vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelp", { bg = bg_menu, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpBorder", { bg = bg_menu, fg = colors.base03 })
  vim.api.nvim_set_hl(0, "BlinkCmpLabel", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "BlinkCmpGhostText", { fg = colors.base03, italic = true })
  vim.api.nvim_set_hl(0, "BlinkCmpKind", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "BlinkCmpKindText", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "BlinkCmpKindMethod", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "BlinkCmpKindFunction", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "BlinkCmpKindConstructor", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "BlinkCmpKindField", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "BlinkCmpKindVariable", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "BlinkCmpKindClass", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "BlinkCmpKindInterface", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "BlinkCmpKindModule", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "BlinkCmpKindProperty", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "BlinkCmpKindKeyword", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "BlinkCmpKindSnippet", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "BlinkCmpKindColor", { fg = colors.base0C })
  vim.api.nvim_set_hl(0, "BlinkCmpKindFile", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "BlinkCmpKindEnum", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "BlinkCmpKindConstant", { fg = colors.base09 })
  vim.api.nvim_set_hl(0, "BlinkCmpKindStruct", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "BlinkCmpKindTypeParameter", { fg = colors.base0A })

  -- Dropbar (breadcrumbs)
  vim.api.nvim_set_hl(0, "DropBarKindFile", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "DropBarKindModule", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindNamespace", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindPackage", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindClass", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindMethod", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "DropBarKindProperty", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "DropBarKindField", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "DropBarKindConstructor", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindEnum", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindInterface", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindFunction", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "DropBarKindVariable", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "DropBarKindConstant", { fg = colors.base09 })
  vim.api.nvim_set_hl(0, "DropBarKindString", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "DropBarKindNumber", { fg = colors.base09 })
  vim.api.nvim_set_hl(0, "DropBarKindBoolean", { fg = colors.base09 })
  vim.api.nvim_set_hl(0, "DropBarKindArray", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindObject", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindKey", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "DropBarKindNull", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "DropBarKindEnumMember", { fg = colors.base09 })
  vim.api.nvim_set_hl(0, "DropBarKindStruct", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DropBarKindEvent", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "DropBarKindOperator", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "DropBarKindTypeParameter", { fg = colors.base0A })

  -- Neo-tree (file explorer)
  local bg_sidebar = transparency_enabled and "NONE" or colors.base00
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = bg_sidebar, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = bg_sidebar, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "NeoTreeFileName", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "NeoTreeFileIcon", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", { fg = colors.base0B, bold = true })
  vim.api.nvim_set_hl(0, "NeoTreeIndentMarker", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "NeoTreeSymbolicLinkTarget", { fg = colors.base0C })
  vim.api.nvim_set_hl(0, "NeoTreeGitAdded", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "NeoTreeGitConflict", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "NeoTreeGitDeleted", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "NeoTreeGitIgnored", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "NeoTreeGitModified", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "NeoTreeGitUnstaged", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "NeoTreeGitUntracked", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "NeoTreeGitStaged", { fg = colors.base0B })

  -- Trouble (diagnostics list)
  vim.api.nvim_set_hl(0, "TroubleNormal", { bg = bg_sidebar, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "TroubleText", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "TroubleSource", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "TroubleCode", { fg = colors.base0B })

  -- Which-key (keybinding help)
  vim.api.nvim_set_hl(0, "WhichKey", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = colors.base05 })
  vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "WhichKeyValue", { fg = colors.base0C })

  -- HLChunk (indent guides)
  vim.api.nvim_set_hl(0, "HLChunkStyle1", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "HLChunkStyle2", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "HLChunkLineNum", { fg = colors.base0D })

  -- DAP (debugger)
  vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "DapLogPoint", { fg = colors.base0C })
  vim.api.nvim_set_hl(0, "DapStopped", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = colors.base01 })

  -- Outline (symbols)
  vim.api.nvim_set_hl(0, "OutlineNormal", { bg = bg_sidebar })
  vim.api.nvim_set_hl(0, "OutlineCurrent", { bg = colors.base02, fg = colors.base0D, bold = true })

  -- Snacks (notifications and utilities)
  vim.api.nvim_set_hl(0, "SnacksNotifierInfo", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "SnacksNotifierWarn", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "SnacksNotifierError", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "SnacksNotifierDebug", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "SnacksNotifierTrace", { fg = colors.base0C })
  vim.api.nvim_set_hl(0, "SnacksNotifierIconInfo", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "SnacksNotifierIconWarn", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "SnacksNotifierIconError", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "SnacksNotifierIconDebug", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "SnacksNotifierIconTrace", { fg = colors.base0C })
  vim.api.nvim_set_hl(0, "SnacksNotifierTitleInfo", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "SnacksNotifierTitleWarn", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "SnacksNotifierTitleError", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "SnacksNotifierTitleDebug", { fg = colors.base03, bold = true })
  vim.api.nvim_set_hl(0, "SnacksNotifierTitleTrace", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "SnacksNotifierBorderInfo", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "SnacksNotifierBorderWarn", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "SnacksNotifierBorderError", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "SnacksNotifierBorderDebug", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "SnacksNotifierBorderTrace", { fg = colors.base0C })

  -- Hop (easy motion)
  vim.api.nvim_set_hl(0, "HopNextKey", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "HopNextKey1", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "HopNextKey2", { fg = colors.base0C })
  vim.api.nvim_set_hl(0, "HopUnmatched", { fg = colors.base03 })

  -- Neogit
  vim.api.nvim_set_hl(0, "NeogitBranch", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "NeogitRemote", { fg = colors.base0C, bold = true })
  vim.api.nvim_set_hl(0, "NeogitHunkHeader", { bg = colors.base01, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "NeogitHunkHeaderHighlight", { bg = colors.base02, fg = colors.base0D })
  vim.api.nvim_set_hl(0, "NeogitDiffAdd", { link = "DiffAdd" })
  vim.api.nvim_set_hl(0, "NeogitDiffDelete", { link = "DiffDelete" })
  vim.api.nvim_set_hl(0, "NeogitDiffContext", { fg = colors.base05 })

  -- Oil (file manager)
  vim.api.nvim_set_hl(0, "OilDir", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "OilDirIcon", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "OilLink", { fg = colors.base0C })
  vim.api.nvim_set_hl(0, "OilLinkTarget", { fg = colors.base0C })
  vim.api.nvim_set_hl(0, "OilCopy", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "OilMove", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "OilChange", { fg = colors.base0A, bold = true })
  vim.api.nvim_set_hl(0, "OilCreate", { fg = colors.base0B, bold = true })
  vim.api.nvim_set_hl(0, "OilDelete", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "OilPermissionNone", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "OilPermissionRead", { fg = colors.base0A })
  vim.api.nvim_set_hl(0, "OilPermissionWrite", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "OilPermissionExecute", { fg = colors.base0B })

  -- Wilder (command line completion)
  vim.api.nvim_set_hl(0, "WilderMenu", { bg = bg_menu, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "WilderAccent", { fg = colors.base0D, bold = true })

  -- Octo (GitHub integration)
  vim.api.nvim_set_hl(0, "OctoEditable", { bg = colors.base01 })
  vim.api.nvim_set_hl(0, "OctoBubble", { bg = colors.base01, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "OctoUser", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "OctoUserViewer", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "OctoDirty", { fg = colors.base08, bold = true })
  vim.api.nvim_set_hl(0, "OctoIssueOpen", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "OctoIssueClosed", { fg = colors.base08 })
  vim.api.nvim_set_hl(0, "OctoPullMerged", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "OctoPullOpen", { fg = colors.base0B })
  vim.api.nvim_set_hl(0, "OctoPullClosed", { fg = colors.base08 })

  -- Markview (markdown preview)
  vim.api.nvim_set_hl(0, "MarkviewHeading1", { link = "@markup.heading.1" })
  vim.api.nvim_set_hl(0, "MarkviewHeading2", { link = "@markup.heading.2" })
  vim.api.nvim_set_hl(0, "MarkviewHeading3", { link = "@markup.heading.3" })
  vim.api.nvim_set_hl(0, "MarkviewHeading4", { link = "@markup.heading.4" })
  vim.api.nvim_set_hl(0, "MarkviewHeading5", { link = "@markup.heading.5" })
  vim.api.nvim_set_hl(0, "MarkviewHeading6", { link = "@markup.heading.6" })
  vim.api.nvim_set_hl(0, "MarkviewCode", { bg = colors.base01 })
  vim.api.nvim_set_hl(0, "MarkviewInlineCode", { bg = colors.base01, fg = colors.base0B })

  -- Treesitter context (sticky headers)
  vim.api.nvim_set_hl(0, "TreesitterContext", { bg = colors.base01 })
  vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { bg = colors.base01, fg = colors.base03 })
  vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = colors.base03 })

  -- Glance (LSP references)
  vim.api.nvim_set_hl(0, "GlancePreviewNormal", { bg = bg_sidebar, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "GlanceListNormal", { bg = bg_sidebar, fg = colors.base05 })
  vim.api.nvim_set_hl(0, "GlanceListBorderBottom", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "GlancePreviewBorderBottom", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "GlanceListMatch", { fg = colors.base0D, bold = true })
  vim.api.nvim_set_hl(0, "GlanceListFilename", { fg = colors.base0E })
  vim.api.nvim_set_hl(0, "GlanceListFilepath", { fg = colors.base03 })

  -- Grug-far (find and replace)
  vim.api.nvim_set_hl(0, "GrugFarResultsMatch", { bg = colors.base0A, fg = colors.base00, bold = true })
  vim.api.nvim_set_hl(0, "GrugFarResultsPath", { fg = colors.base0D })
  vim.api.nvim_set_hl(0, "GrugFarResultsLineNo", { fg = colors.base03 })
  vim.api.nvim_set_hl(0, "GrugFarInputLabel", { fg = colors.base0E, bold = true })
  vim.api.nvim_set_hl(0, "GrugFarInputPlaceholder", { fg = colors.base03 })
end

-- Apply highlights immediately (colors should be available from base16-colorscheme.setup() call)
apply_highlights()

-- Apply transparency immediately (nix_transparency_enabled is already set by nix during init)
apply_transparency()

-- Reapply after any colorscheme change to override defaults
-- This is important because base16-colorscheme.setup() triggers ColorScheme event
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Apply highlights immediately, then transparency
    apply_highlights()
    -- Schedule transparency to run after ColorScheme event completes
    vim.schedule(apply_transparency)
  end,
  desc = "Reapply custom highlights and transparency after colorscheme change",
})

vim.api.nvim_create_user_command("Colorscheme", function()
  local original_transparency_state = get_transparency_state()

  require("snacks").picker.colorschemes({
    layout = "right",
    on_show = function()
      if original_transparency_state then
        vim.g.transparency_user_override = false
        local current_colorscheme = vim.g.colors_name
        if current_colorscheme then
          vim.cmd.colorscheme(current_colorscheme)
        end
      end
    end,
    on_close = function()
      vim.g.transparency_user_override = original_transparency_state
      -- Reapply highlights and transparency after colorscheme selection
      apply_highlights()
      if original_transparency_state then
        apply_transparency()
      end
    end,
  })
end, {
  desc = "Open colorscheme picker",
})

vim.api.nvim_create_user_command("TransparencyToggle", function()
  local current_state = get_transparency_state()
  local new_state = not current_state
  vim.g.transparency_user_override = new_state

  if new_state then
    -- Enable transparency: reapply base16 colors, then our custom highlights, then transparency
    reload_base16_colorscheme()
    vim.schedule(function()
      apply_highlights()
      apply_transparency()
      print("Transparency enabled")
    end)
  else
    -- Disable transparency: reload base16 colorscheme to restore backgrounds
    reload_base16_colorscheme()
    vim.schedule(function()
      apply_highlights()
      print("Transparency disabled")
    end)
  end
end, {
  desc = "Toggle transparency on/off",
})

vim.api.nvim_create_user_command("HighlightAudit", function()
  local output_file = vim.fn.expand("~/nvim-highlights-audit.txt")
  local lines = {}

  local highlights = vim.fn.getcompletion("", "highlight")
  table.sort(highlights)

  table.insert(lines, "=== Neovim Highlight Groups Audit ===")
  table.insert(lines, "Transparency enabled: " .. tostring(get_transparency_state()))
  table.insert(lines, "Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
  table.insert(lines, "")

  for _, hl_name in ipairs(highlights) do
    local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
    if next(hl) ~= nil then
      local hl_str = hl_name .. ": "
      local parts = {}

      if hl.fg then
        table.insert(parts, string.format("fg=#%06x", hl.fg))
      end
      if hl.bg then
        table.insert(parts, string.format("bg=#%06x", hl.bg))
      end
      if hl.sp then
        table.insert(parts, string.format("sp=#%06x", hl.sp))
      end
      if hl.bold then
        table.insert(parts, "bold")
      end
      if hl.italic then
        table.insert(parts, "italic")
      end
      if hl.underline then
        table.insert(parts, "underline")
      end
      if hl.strikethrough then
        table.insert(parts, "strikethrough")
      end
      if hl.link then
        table.insert(parts, "link=" .. hl.link)
      end

      if #parts > 0 then
        hl_str = hl_str .. table.concat(parts, " ")
        table.insert(lines, hl_str)
      end
    end
  end

  vim.fn.writefile(lines, output_file)
  print("Highlight audit written to: " .. output_file)
end, {
  desc = "Dump all highlight groups to ~/nvim-highlights-audit.txt",
})
