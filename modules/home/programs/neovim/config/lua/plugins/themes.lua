local terminal = require("utils.terminal")
local ls_colors = require("utils.ls_colors")
local palette_builder = require("utils.palette")

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
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "NeoTreeEndOfBuffer",
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
  "TreesitterContext",
  "TreesitterContextLineNumber",
  "WhichKeyBorder",
  "WhichKeyFloat",
  "WinBar",
  "WinBarNC",
  "WinSeparator",
}

local HIGHLIGHT_OVERRIDES = {
  WilderSeparator = { link = "Comment" },
  WilderSpinner = { link = "DiagnosticInfo" },
  DiagnosticError = { link = "ErrorMsg" },
  DiagnosticHint = { link = "Comment" },
  DiagnosticInfo = { link = "Directory" },
  DiagnosticOk = { link = "Question" },
  DiagnosticWarn = { link = "WarningMsg" },
  DiagnosticVirtualTextError = { link = "DiagnosticError" },
  DiagnosticVirtualTextWarn = { link = "DiagnosticWarn" },
  DiagnosticVirtualTextInfo = { link = "DiagnosticInfo" },
  DiagnosticVirtualTextHint = { link = "DiagnosticHint" },
  ["@constant.builtin"] = { link = "Special" },
  ["@constructor"] = { link = "Typedef" },
  ["@function.builtin"] = { link = "Special" },
  ["@markup.heading"] = { link = "Title" },
  ["@markup.link.label"] = { link = "Special" },
  ["@markup.raw"] = { link = "String" },
  ["@module"] = { link = "Include" },
  ["@string.special.url"] = { link = "Underlined" },
  TreesitterContextBottom = {},
  ["@variable"] = { link = "Identifier" },
  ["@variable.builtin"] = { link = "Special" },
  ["@variable.member"] = { link = "Identifier" },
  ["@variable.parameter"] = { link = "Identifier" },
}

local ls_data = ls_colors.parse()
local ls_palette = ls_colors.extract_palette(ls_data)
local transparent = terminal.is_transparent()

local initial_palette = palette_builder.build({}, ls_palette)

local function neogit_highlights(c)
  local U = require("catppuccin.utils.colors")

  local section = { link = "Statement" }

  return {
    NeogitNormal = { link = "Normal" },
    NeogitFloat = { link = "NormalFloat" },
    NeogitNormalFloat = { link = "NormalFloat" },
    NeogitFloatBorder = { link = "FloatBorder" },
    NeogitFloatHeader = { fg = c.blue, bg = U.darken(c.blue, 0.12, c.base), bold = true },
    NeogitFloatHeaderHighlight = { fg = c.sapphire, bg = U.darken(c.blue, 0.20, c.base), bold = true },
    NeogitWinSeparator = { link = "WinSeparator" },
    NeogitSignColumn = { fg = "NONE", bg = "NONE" },
    NeogitFoldColumn = { fg = "NONE", bg = "NONE" },
    NeogitCursorLine = { link = "CursorLine" },
    NeogitCursorLineNr = { link = "CursorLineNr" },

    NeogitCommitViewDescription = { link = "Normal" },

    NeogitDiffAdditions = { link = "Added" },
    NeogitDiffDeletions = { link = "Removed" },

    NeogitDiffContext = { link = "Normal" },
    NeogitDiffContextHighlight = { bg = c.surface0 },
    NeogitDiffContextCursor = { bg = c.surface1 },

    NeogitDiffAdd = { link = "DiffAdd" },
    NeogitDiffAddHighlight = { link = "DiffAdd" },
    NeogitDiffAddCursor = { link = "DiffAdd" },
    NeogitDiffAddInline = { bg = U.darken(c.green, 0.20, c.base), fg = c.green, bold = true },

    NeogitDiffDelete = { link = "DiffDelete" },
    NeogitDiffDeleteHighlight = { link = "DiffDelete" },
    NeogitDiffDeleteCursor = { link = "DiffDelete" },
    NeogitDiffDeleteInline = { bg = U.darken(c.red, 0.20, c.base), fg = c.red, bold = true },

    NeogitDiffHeader = { link = "Function" },
    NeogitDiffHeaderHighlight = { fg = c.blue, bg = c.surface0, bold = true },
    NeogitDiffHeaderCursor = { fg = c.blue, bg = c.surface1, bold = true },

    NeogitHunkHeader = { fg = c.blue, bg = c.surface0, bold = true },
    NeogitHunkHeaderHighlight = { fg = c.blue, bg = c.surface1, bold = true },
    NeogitHunkHeaderCursor = { fg = c.blue, bg = c.surface2, bold = true },

    NeogitHunkMergeHeader = { fg = c.teal, bg = c.surface0, bold = true },
    NeogitHunkMergeHeaderHighlight = { fg = c.teal, bg = c.surface1, bold = true },
    NeogitHunkMergeHeaderCursor = { fg = c.teal, bg = c.surface2, bold = true },

    NeogitCommitViewHeader = { fg = c.blue, bg = c.surface0, bold = true },
    NeogitCommitViewHeaderHighlight = { fg = c.sapphire, bg = c.surface1, bold = true },
    NeogitCommitViewHeaderCursor = { fg = c.blue, bg = c.surface2, bold = true },

    NeogitSectionHeader = section,
    NeogitSectionHeaderCount = { fg = c.subtext1, bold = true },
    NeogitUntrackedfiles = section,
    NeogitUnstagedchanges = section,
    NeogitUnmergedchanges = section,
    NeogitUnpulledchanges = section,
    NeogitUnpushedchanges = section,
    NeogitStagedchanges = section,
    NeogitRecentcommits = section,
    NeogitStashes = section,
    NeogitRebasing = section,
    NeogitReverting = section,
    NeogitPicking = section,
    NeogitMerging = section,
    NeogitBisecting = section,
    NeogitUnmergedInto = { link = "Function" },
    NeogitUnpulledFrom = { link = "Function" },
    NeogitUnpushedTo = { fg = c.lavender, bold = true },

    NeogitStatusHEAD = { fg = c.text, bold = true },
    NeogitActiveItem = { fg = c.crust, bg = c.peach, bold = true },
    NeogitBranchHead = { fg = c.sapphire, bold = true, underline = true },

    NeogitFold = { fg = "NONE", bg = "NONE" },

    NeogitBranch = { link = "Number" },
    NeogitRemote = { fg = c.green, bold = true },
    NeogitTagName = { link = "DiagnosticWarn" },
    NeogitTagDistance = { link = "Directory" },

    NeogitFilePath = { fg = c.blue, italic = true },
    NeogitObjectId = { link = "Comment" },
    NeogitStash = { link = "Comment" },
    NeogitSubtleText = { link = "Comment" },
    NeogitRebaseDone = { link = "Comment" },

    NeogitChangeModified = { fg = c.blue, bold = true, italic = true },
    NeogitChangeAdded = { fg = c.green, bold = true, italic = true },
    NeogitChangeDeleted = { fg = c.red, bold = true, italic = true },
    NeogitChangeRenamed = { fg = c.mauve, bold = true, italic = true },
    NeogitChangeUpdated = { fg = c.peach, bold = true, italic = true },
    NeogitChangeCopied = { fg = c.pink, bold = true, italic = true },
    NeogitChangeNewFile = { fg = c.green, bold = true, italic = true },
    NeogitChangeUnmerged = { fg = c.yellow, bold = true, italic = true },

    NeogitChangeMuntracked = { link = "NeogitChangeModified" },
    NeogitChangeAuntracked = { link = "NeogitChangeAdded" },
    NeogitChangeNuntracked = { link = "NeogitChangeNewFile" },
    NeogitChangeDuntracked = { link = "NeogitChangeDeleted" },
    NeogitChangeCuntracked = { link = "NeogitChangeCopied" },
    NeogitChangeUuntracked = { link = "NeogitChangeUpdated" },
    NeogitChangeRuntracked = { link = "NeogitChangeRenamed" },
    NeogitChangeDDuntracked = { link = "NeogitChangeUnmerged" },
    NeogitChangeUUuntracked = { link = "NeogitChangeUnmerged" },
    NeogitChangeAAuntracked = { link = "NeogitChangeUnmerged" },
    NeogitChangeDUuntracked = { link = "NeogitChangeUnmerged" },
    NeogitChangeUDuntracked = { link = "NeogitChangeUnmerged" },
    NeogitChangeAUuntracked = { link = "NeogitChangeUnmerged" },
    NeogitChangeUAuntracked = { link = "NeogitChangeUnmerged" },
    NeogitChangeUntrackeduntracked = { fg = "NONE" },
    NeogitChangeMunstaged = { link = "NeogitChangeModified" },
    NeogitChangeAunstaged = { link = "NeogitChangeAdded" },
    NeogitChangeNunstaged = { link = "NeogitChangeNewFile" },
    NeogitChangeDunstaged = { link = "NeogitChangeDeleted" },
    NeogitChangeCunstaged = { link = "NeogitChangeCopied" },
    NeogitChangeUunstaged = { link = "NeogitChangeUpdated" },
    NeogitChangeRunstaged = { link = "NeogitChangeRenamed" },
    NeogitChangeTunstaged = { link = "NeogitChangeUpdated" },
    NeogitChangeDDunstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeUUunstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeAAunstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeDUunstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeUDunstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeAUunstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeUAunstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeUntrackedunstaged = { fg = "NONE" },
    NeogitChangeMstaged = { link = "NeogitChangeModified" },
    NeogitChangeAstaged = { link = "NeogitChangeAdded" },
    NeogitChangeNstaged = { link = "NeogitChangeNewFile" },
    NeogitChangeDstaged = { link = "NeogitChangeDeleted" },
    NeogitChangeCstaged = { link = "NeogitChangeCopied" },
    NeogitChangeUstaged = { link = "NeogitChangeUpdated" },
    NeogitChangeRstaged = { link = "NeogitChangeRenamed" },
    NeogitChangeTstaged = { link = "NeogitChangeUpdated" },
    NeogitChangeDDstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeUUstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeAAstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeDUstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeUDstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeAUstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeUAstaged = { link = "NeogitChangeUnmerged" },
    NeogitChangeUntrackedstaged = { fg = "NONE" },

    NeogitGraphAuthor = { fg = c.peach },
    NeogitGraphBlack = { fg = c.surface2 },
    NeogitGraphBoldBlack = { fg = c.surface2, bold = true },
    NeogitGraphRed = { fg = c.red },
    NeogitGraphBoldRed = { fg = c.red, bold = true },
    NeogitGraphGreen = { fg = c.green },
    NeogitGraphBoldGreen = { fg = c.green, bold = true },
    NeogitGraphYellow = { fg = c.yellow },
    NeogitGraphBoldYellow = { fg = c.yellow, bold = true },
    NeogitGraphBlue = { fg = c.blue },
    NeogitGraphBoldBlue = { fg = c.blue, bold = true },
    NeogitGraphPurple = { fg = c.lavender },
    NeogitGraphBoldPurple = { fg = c.lavender, bold = true },
    NeogitGraphCyan = { fg = c.teal },
    NeogitGraphBoldCyan = { fg = c.teal, bold = true },
    NeogitGraphWhite = { fg = c.text },
    NeogitGraphBoldWhite = { fg = c.text, bold = true },
    NeogitGraphGray = { fg = c.subtext1 },
    NeogitGraphBoldGray = { fg = c.subtext1, bold = true },
    NeogitGraphOrange = { fg = c.peach },
    NeogitGraphBoldOrange = { fg = c.peach, bold = true },

    NeogitSignatureGood = { link = "DiagnosticOk" },
    NeogitSignatureGoodUnknown = { fg = c.teal },
    NeogitSignatureGoodExpired = { link = "DiagnosticWarn" },
    NeogitSignatureGoodExpiredKey = { link = "DiagnosticWarn" },
    NeogitSignatureGoodRevokedKey = { fg = c.peach },
    NeogitSignatureBad = { link = "DiagnosticError" },
    NeogitSignatureMissing = { fg = c.subtext1 },
    NeogitSignatureNone = { link = "Comment" },

    NeogitPopupSectionTitle = { link = "Statement" },
    NeogitPopupBranchName = { link = "Number" },
    NeogitPopupBold = { bold = true },
    NeogitPopupSwitchKey = { link = "Identifier" },
    NeogitPopupSwitchEnabled = { link = "DiagnosticOk" },
    NeogitPopupSwitchDisabled = { link = "Comment" },
    NeogitPopupOptionKey = { link = "Identifier" },
    NeogitPopupOptionEnabled = { link = "DiagnosticOk" },
    NeogitPopupOptionDisabled = { link = "Comment" },
    NeogitPopupConfigKey = { link = "Identifier" },
    NeogitPopupConfigEnabled = { link = "DiagnosticOk" },
    NeogitPopupConfigDisabled = { link = "Comment" },
    NeogitPopupActionKey = { link = "Identifier" },
    NeogitPopupActionDisabled = { link = "Comment" },

    NeogitCommandText = { link = "Normal" },
    NeogitCommandTime = { link = "Comment" },
    NeogitCommandCodeNormal = { link = "DiagnosticOk" },
    NeogitCommandCodeError = { link = "DiagnosticError" },

    NeogitNotificationInfo = { link = "DiagnosticInfo" },
    NeogitNotificationWarning = { link = "DiagnosticWarn" },
    NeogitNotificationError = { link = "DiagnosticError" },
  }
end

local function setup_catppuccin(palette, is_transparent)
  local color_overrides = {}
  local flavor
  if palette then
    color_overrides.all = palette
    if palette.base then
      flavor = palette_builder.detect_dark_light(palette.base) == "dark" and "mocha" or "latte"
    else
      flavor = vim.o.background == "dark" and "mocha" or "latte"
    end
  else
    flavor = vim.o.background == "dark" and "mocha" or "latte"
  end

  require("catppuccin").setup({
    flavour = flavor,
    show_end_of_buffer = false,
    transparent_background = is_transparent,
    styles = SYNTAX_STYLES,
    color_overrides = color_overrides,
    custom_highlights = function(colors)
      return vim.tbl_extend("force", {
        CursorLineNr = { fg = colors.lavender, bold = true },

        Visual = { bg = colors.overlay2, fg = colors.crust, bold = true },
        VisualNOS = { bg = colors.overlay2, fg = colors.crust, bold = true },

        CursorLine = { bg = colors.overlay1 },

        WilderPrefixHidden = { fg = colors.surface0 },
        WilderPrefixSelected = { fg = colors.lavender },
        WilderSelected = { bold = true, sp = colors.lavender },
        WilderAccent = { fg = colors.red },
        WilderSelectedAccent = { fg = colors.red, bold = true, sp = colors.red },
      }, neogit_highlights(colors))
    end,
    integrations = {
      cmp = true,
      dap = true,
      dap_ui = true,
      fzf = true,
      gitsigns = true,
      grug_far = true,
      hop = true,
      neogit = true,
      notify = true,
      nvimtree = true,
      markview = true,
      render_markdown = true,
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
end

local function apply_highlights()
  if transparent then
    for _, group in ipairs(TRANSPARENT_GROUPS) do
      vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
  end

  for group, attrs in pairs(HIGHLIGHT_OVERRIDES) do
    vim.api.nvim_set_hl(0, group, attrs)
  end
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      setup_catppuccin(initial_palette, transparent)
      vim.cmd.colorscheme("catppuccin")
      apply_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "catppuccin*",
        callback = apply_highlights,
      })

      terminal.query_colors(function(term_colors, bg)
        if vim.tbl_isempty(term_colors) and not bg then
          return
        end

        local full_palette = palette_builder.build(term_colors, ls_palette, bg)
        setup_catppuccin(full_palette, transparent)
        vim.cmd.colorscheme("catppuccin")
      end)
    end,
  },
}
