if not vim.g.nix_managed then
  vim.cmd.colorscheme("base16-tokyo-city-terminal-light")
end

local c = require("base16-colorscheme").colors

local colors = {
  background = { primary = c.base00, secondary = c.base01 },
  foreground = { primary = c.base05, secondary = c.base04, subtle = c.base03, muted = c.base03 },
  accent = { primary = c.base0D, secondary = c.base0E },
  syntax = {
    variable = c.base08,
    builtin = c.base0C,
    constant = c.base09,
    type = c.base0A,
    string = c.base0B,
    operator = c.base05,
    ["function"] = c.base0D,
    keyword = c.base0E,
    comment = c.base03,
    number = c.base09,
  },
  semantic = {
    error = c.base08,
    warning = c.base0A,
    info = c.base0C,
    success = c.base0B,
  },
  ui = {
    cursor = c.base0D,
    cursor_line = c.base01,
    line_number = c.base03,
    line_number_active = c.base0D,
    visual_selection = c.base02,
    match_paren = c.base03,
  },
  diff = {
    add = c.base0B,
    add_bg = c.base01,
    change = c.base0A,
    change_bg = c.base01,
    delete = c.base08,
    delete_bg = c.base01,
    text = c.base0D,
  },
  plugins = {
    search = {
      match_bg = c.base0A,
      match_fg = c.base00,
      incremental_bg = c.base09,
      incremental_fg = c.base00,
    },
    completion = {
      border = c.base03,
      selection_bg = c.base02,
      selection_fg = c.base0D,
    },
    window = {
      separator = c.base01,
      statusline_active = c.base05,
      statusline_inactive = c.base03,
      winbar_active = c.base05,
      winbar_inactive = c.base03,
    },
  },
}

local function apply_theme()
  local is_trans = (vim.g.transparency_user_override ~= nil) and vim.g.transparency_user_override
    or (vim.g.nix_transparency_enabled or false)

  local bg_p = is_trans and "NONE" or colors.background.primary
  local bg_s = is_trans and "NONE" or colors.background.secondary

  local hls = {
    -- Core
    Normal = { fg = colors.foreground.primary, bg = bg_p },
    NormalNC = { fg = colors.foreground.primary, bg = bg_p },
    Cursor = { bg = colors.ui.cursor, fg = colors.background.primary },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    TermCursor = { link = "Cursor" },
    TermCursorNC = { bg = colors.ui.cursor, fg = colors.background.primary },
    CursorLine = { bg = is_trans and "NONE" or colors.ui.cursor_line },
    CursorColumn = { bg = is_trans and "NONE" or colors.ui.cursor_line },
    CursorLineNr = { bg = "NONE", fg = colors.ui.line_number_active, bold = true },
    LineNr = { bg = "NONE", fg = colors.ui.line_number },
    LineNrAbove = { fg = colors.ui.line_number, bg = "NONE" },
    LineNrBelow = { fg = colors.ui.line_number, bg = "NONE" },
    Visual = { bg = colors.ui.visual_selection, fg = colors.foreground.primary, bold = true },
    VisualNOS = { bg = colors.ui.visual_selection, fg = colors.foreground.primary },
    MatchParen = { bg = colors.ui.match_paren, fg = colors.background.primary, bold = true },
    SignColumn = { bg = "NONE" },
    FoldColumn = { bg = "NONE" },

    -- Search
    Search = { bg = colors.plugins.search.match_bg, fg = colors.plugins.search.match_fg, bold = true },
    IncSearch = { bg = colors.plugins.search.incremental_bg, fg = colors.plugins.search.incremental_fg, bold = true },
    CurSearch = { link = "IncSearch" },

    -- Window & Menu
    StatusLine = { bg = "NONE", fg = colors.plugins.window.statusline_active },
    StatusLineNC = { bg = "NONE", fg = colors.plugins.window.statusline_inactive },
    WinBar = { bg = "NONE", fg = colors.plugins.window.winbar_active },
    WinBarNC = { bg = "NONE", fg = colors.plugins.window.winbar_inactive },
    WinSeparator = { fg = colors.plugins.window.separator, bold = true },
    Pmenu = { bg = "NONE", fg = colors.foreground.primary },
    PmenuBorder = { bg = "NONE", fg = colors.plugins.completion.border },
    PmenuSel = { bg = colors.plugins.completion.selection_bg, fg = colors.plugins.completion.selection_fg, bold = true },

    -- Floats
    NormalFloat = { bg = "NONE", fg = colors.foreground.primary },
    FloatBorder = { bg = "NONE", fg = colors.syntax.comment },
    FloatTitle = { bg = "NONE", fg = colors.accent.primary, bold = true },
    DropBarMenuFloatBorder = { bg = "NONE", fg = colors.foreground.subtle },

    -- Diff / Git
    DiffAdd = { bg = colors.diff.add_bg },
    DiffChange = { bg = colors.diff.change_bg },
    DiffDelete = { bg = colors.diff.delete_bg },
    DiffText = { bg = colors.diff.text, fg = colors.background.primary, bold = true },

    -- Neogit Overrides
    NeogitDiffContext = { bg = "NONE", fg = colors.foreground.primary },
    NeogitDiffContextCursor = { bg = colors.background.secondary, fg = colors.foreground.primary, bold = true },
    NeogitDiffContextHighlight = { bg = colors.background.secondary, fg = colors.foreground.primary },
    NeogitDiffAdd = { bg = colors.diff.add_bg, fg = colors.diff.add },
    NeogitDiffAddCursor = { bg = colors.diff.add_bg, fg = colors.diff.add, bold = true },
    NeogitDiffAddHighlight = { bg = colors.diff.add_bg, fg = colors.diff.add },
    NeogitDiffDelete = { bg = colors.diff.delete_bg, fg = colors.diff.delete },
    NeogitDiffDeleteCursor = { bg = colors.diff.delete_bg, fg = colors.diff.delete, bold = true },
    NeogitDiffDeleteHighlight = { bg = colors.diff.delete_bg, fg = colors.diff.delete },

    -- Diagnostics
    DiagnosticError = { fg = colors.semantic.error, bold = true },
    DiagnosticWarn = { fg = colors.semantic.warning, bold = true },
    DiagnosticInfo = { fg = colors.semantic.info, bold = true },
    DiagnosticHint = { fg = colors.semantic.info, bold = true },
    DiagnosticVirtualLinesError = { fg = colors.semantic.error, bold = true },
    DiagnosticVirtualLinesWarn = { fg = colors.semantic.warning, bold = true },
    DiagnosticVirtualLinesInfo = { fg = colors.semantic.info, bold = true },
    DiagnosticVirtualLinesHint = { fg = colors.semantic.info, bold = true },

    -- Wilder
    WilderSelected = { fg = colors.plugins.completion.selection_fg, bold = true },
    WilderAccent = { fg = colors.accent.primary, bold = true },
    WilderWildmenuSelected = { fg = colors.plugins.completion.selection_fg, bold = true, bg = "NONE" },
    WilderWildmenuAccent = { fg = colors.accent.primary, bold = true },
    WilderSeparator = { fg = colors.syntax.comment },
    WilderSpinner = { fg = colors.syntax.comment, bold = true },

    -- Outline
    OutlineCurrent = { fg = colors.accent.primary, bold = true, bg = colors.background.secondary },
    OutlineGuides = { fg = colors.syntax.comment },
    OutlineFoldMarker = { fg = colors.foreground.subtle },
    OutlineDetails = { fg = colors.syntax.comment },
    OutlineLineno = { fg = colors.ui.line_number },
    OutlineJumpHighlight = { fg = colors.background.primary, bg = colors.accent.primary },

    -- NeoTree Overrides
    NeoTreeNormal = { bg = "NONE", fg = colors.foreground.primary },
    NeoTreeNormalNC = { bg = "NONE", fg = colors.foreground.primary },
    NeoTreeEndOfBuffer = { bg = "NONE", fg = "NONE" },
    NeoTreeFloatBorder = { bg = "NONE", fg = colors.syntax.comment },
    NeoTreeFloatTitle = { bg = "NONE", fg = colors.accent.primary, bold = true },
    NeoTreeTitleBar = { bg = "NONE", fg = colors.accent.primary, bold = true },
    NeoTreeCursorLine = { bg = colors.background.secondary, bold = true },
    NeoTreeDimText = { fg = colors.foreground.muted },
    NeoTreeDirectoryIcon = { fg = colors.accent.secondary },
    NeoTreeDirectoryName = { fg = colors.foreground.primary },
    NeoTreeFileName = { fg = colors.foreground.primary },
    NeoTreeFileIcon = { fg = colors.foreground.subtle },
    NeoTreeFileNameOpened = { fg = colors.accent.primary, bold = true },
    NeoTreeFilterTerm = { fg = colors.accent.primary, bold = true },
    NeoTreeFloatNormal = { bg = "NONE", fg = colors.foreground.primary },
    NeoTreeGitAdded = { fg = colors.diff.add },
    NeoTreeGitConflict = { fg = colors.semantic.error, bold = true },
    NeoTreeGitDeleted = { fg = colors.diff.delete },
    NeoTreeGitIgnored = { fg = colors.foreground.muted },
    NeoTreeGitModified = { fg = colors.diff.change },
    NeoTreeGitUnstaged = { fg = colors.semantic.warning },
    NeoTreeGitUntracked = { fg = colors.foreground.subtle },
    NeoTreeGitStaged = { fg = colors.diff.add },
    NeoTreeIndentMarker = { fg = colors.syntax.comment },
    NeoTreeExpander = { fg = colors.syntax.comment },
    NeoTreeRootName = { fg = colors.accent.primary, bold = true },
    NeoTreeSymbolicLinkTarget = { fg = colors.accent.secondary },
    NeoTreeTabActive = { bg = colors.background.secondary, fg = colors.accent.primary, bold = true },
    NeoTreeTabInactive = { bg = "NONE", fg = colors.foreground.muted },
    NeoTreeTabSeparatorActive = { bg = colors.background.secondary, fg = colors.accent.primary },
    NeoTreeTabSeparatorInactive = { bg = "NONE", fg = colors.syntax.comment },
    NeoTreeWinSeparator = { fg = colors.plugins.window.separator, bold = true },

    -- Syntax / TS
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

    -- LSP
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
    LspInlayHint = { fg = colors.foreground.muted, bg = "NONE" },

    -- Telescope
    TelescopeNormal = { link = "Normal" },
    TelescopeBorder = { link = "FloatBorder" },
    TelescopeSelection = { fg = colors.semantic.error, bold = true },
    telescopeselectionCaret = { link = "PmenuSel" },
    TelescopePromptPrefix = { fg = colors.accent.primary, bold = true },
    TelescopePreviewMatch = { bg = colors.semantic.warning, fg = colors.background.primary, bold = true },

    -- Blink
    BlinkCmpMenu = { link = "Pmenu" },
    BlinkCmpMenuBorder = { link = "PmenuBorder" },
    BlinkCmpMenuSelection = { link = "PmenuSel" },
    BlinkCmpDoc = { link = "NormalFloat" },
    BlinkCmpDocBorder = { link = "FloatBorder" },
    BlinkCmpLabel = { fg = colors.foreground.primary },
    BlinkCmpLabelMatch = { fg = colors.accent.primary, bold = true },

    -- GitSigns
    GitSignsAdd = { fg = colors.diff.add, bold = true },
    GitSignsChange = { fg = colors.diff.change, bold = true },
    GitSignsDelete = { fg = colors.diff.delete, bold = true },

    -- Snacks
    SnacksPicker = { link = "Normal" },
    SnacksPickerBorder = { link = "FloatBorder" },
    SnacksPickerMatch = { fg = colors.accent.primary, bold = true },
  }

  for name, hl in pairs(hls) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

-- Commands
vim.api.nvim_create_user_command("TransparencyToggle", function()
  if vim.g.transparency_user_override == nil then
    vim.g.transparency_user_override = not (vim.g.nix_transparency_enabled or false)
  else
    vim.g.transparency_user_override = not vim.g.transparency_user_override
  end
  apply_theme()
  vim.cmd("redraw!")
end, {})

vim.api.nvim_create_user_command("Colorscheme", function()
  require("snacks").picker.colorschemes()
end, {})

-- Init
apply_theme()

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_theme,
})
