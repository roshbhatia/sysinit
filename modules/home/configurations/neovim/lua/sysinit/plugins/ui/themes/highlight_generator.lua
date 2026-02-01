local M = {}

function M.generate_cursor_highlights()
  return {
    -- Don't override these - let the colorscheme define them
  }
end

function M.generate_menu_highlights()
  return {
    PmenuSel = { link = "Visual" },
    Pmenu = { link = "NormalFloat" },
    -- Don't override PmenuSbar and PmenuThumb - let the colorscheme define them
  }
end

function M.generate_diff_highlights()
  return {
    -- Don't override these - let the colorscheme define them
  }
end

function M.generate_gitsigns_highlights()
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

function M.generate_treesitter_highlights()
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

    -- Markup (Markdown)
    ["@markup.heading"] = { link = "Title" },
    ["@markup.raw"] = { link = "String" },
    ["@markup.link.label"] = { link = "Special" },
    ["@markup.list"] = { link = "Delimiter" },
  }
end

function M.generate_diagnostic_highlights()
  return {
    DiagnosticError = { link = "ErrorMsg" },
    DiagnosticWarn = { link = "WarningMsg" },
    DiagnosticInfo = { link = "Identifier" },
    DiagnosticHint = { link = "Comment" },
    DiagnosticOk = { link = "Question" },

    -- Signs usually look best linked to their base diagnostic
    DiagnosticSignError = { link = "DiagnosticError" },
    DiagnosticSignWarn = { link = "DiagnosticWarn" },
    DiagnosticSignInfo = { link = "DiagnosticInfo" },
    DiagnosticSignHint = { link = "DiagnosticHint" },
  }
end

function M.generate_transparency_highlights(transparency)
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

function M.generate_lsp_highlights(_)
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

function M.generate_core_highlights(transparency)
  return vim.tbl_extend(
    "force",
    M.generate_transparency_highlights(transparency),
    M.generate_cursor_highlights(),
    M.generate_menu_highlights(),
    M.generate_diff_highlights(),
    M.generate_gitsigns_highlights(),
    M.generate_treesitter_highlights(),
    M.generate_diagnostic_highlights(),
    M.generate_lsp_highlights()
  )
end

function M.apply_highlights(highlights)
  for name, hl in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

return M
