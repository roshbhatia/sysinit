local highlight_gen = require("sysinit.utils.highlight_generator")

local M = {}

function M.apply(theme_config)
  local c = theme_config.semanticColors
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
    TelescopeNormal = { bg = "NONE", fg = c.foreground.primary },
    TelescopeSelection = {
      bg = c.background.secondary,
      fg = c.plugins.telescope.selection_fg,
      bold = true,
    },
    TelescopeTitle = { bg = "NONE", fg = c.plugins.telescope.title, bold = true },
    TelescopePromptNormal = { bg = "NONE", fg = c.foreground.primary },
    TelescopePromptBorder = { bg = "NONE", fg = c.plugins.telescope.border },
    TelescopePromptTitle = { bg = "NONE", fg = c.plugins.telescope.title, bold = true },
    TelescopeResultsNormal = { bg = "NONE", fg = c.foreground.primary },
    TelescopeResultsBorder = { bg = "NONE", fg = c.plugins.telescope.border },
    TelescopeResultsTitle = { bg = "NONE", fg = c.plugins.telescope.title, bold = true },
    TelescopePreviewNormal = { bg = "NONE", fg = c.foreground.primary },
    TelescopePreviewBorder = { bg = "NONE", fg = c.plugins.telescope.border },
    TelescopePreviewTitle = { bg = "NONE", fg = c.plugins.telescope.title, bold = true },

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

    DiagnosticVirtualLinesError = { fg = c.semantic.error, bold = true },
    DiagnosticVirtualLinesWarn = { fg = c.semantic.warning, bold = true },
    DiagnosticVirtualLinesInfo = { fg = c.semantic.info, bold = true },
    DiagnosticVirtualLinesHint = { fg = c.semantic.info, bold = true },

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

return M
