if not vim.g.nix_managed then
  vim.cmd.colorscheme("base16-tokyo-city-terminal-light")
end

local c = require("base16-colorscheme").colors

local transparency_enabled = (vim.g.transparency_user_override ~= nil) and vim.g.transparency_user_override
  or (vim.g.nix_transparency_enabled or false)

local bg_val = transparency_enabled and "NONE" or c.base00
local bg_sec = transparency_enabled and "NONE" or c.base01

local function apply_theme()
  -- "Semantic" color mappings
  local theme = {
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
    semantic = { error = c.base08, warning = c.base0A, info = c.base0C, success = c.base0B },
    accent = { primary = c.base0D, secondary = c.base0E },
    diff = { add = c.base0B, change = c.base0A, delete = c.base08 },
  }

  local highlights = {
    -- Core Editor UI
    Normal = { bg = bg_val, fg = c.base05 },
    NormalNC = { bg = bg_val, fg = c.base05 },
    SignColumn = { bg = bg_val, fg = c.base03 },
    Cursor = { bg = theme.accent.primary, fg = bg_val },
    CursorLine = { bg = bg_sec },
    CursorLineNr = { bg = "NONE", fg = theme.accent.primary, bold = true },
    LineNr = { bg = "NONE", fg = c.base03 },
    LineNrAbove = { bg = "NONE", fg = c.base03 },
    LineNrBelow = { bg = "NONE", fg = c.base03 },
    Visual = { bg = c.base02, fg = c.base05, bold = true },
    Search = { bg = theme.semantic.warning, fg = c.base00, bold = true },
    IncSearch = { bg = theme.semantic.error, fg = c.base00, bold = true },
    MatchParen = { bg = c.base02, fg = c.base0D, bold = true },
    WinSeparator = { fg = c.base03, bold = true },
    EndOfBuffer = { bg = "NONE", fg = bg_val },

    -- Floating Windows
    NormalFloat = { bg = bg_val, fg = c.base05 },
    FloatBorder = { bg = "NONE", fg = c.base03 },
    FloatTitle = { bg = "NONE", fg = theme.accent.primary, bold = true },
    Pmenu = { bg = bg_val, fg = c.base05 },
    PmenuSel = { bg = "NONE", fg = theme.accent.primary, bold = true },
    PmenuBorder = { bg = "NONE", fg = c.base03 },

    -- TreeSitter Syntax
    ["@variable"] = { fg = theme.syntax.variable },
    ["@variable.builtin"] = { fg = theme.syntax.builtin, bold = true },
    ["@variable.parameter"] = { fg = theme.syntax.variable, italic = true },
    ["@function"] = { fg = theme.syntax["function"], bold = true },
    ["@keyword"] = { fg = theme.syntax.keyword, bold = true },
    ["@string"] = { fg = theme.syntax.string },
    ["@type"] = { fg = theme.syntax.type, bold = true },
    ["@constant"] = { fg = theme.syntax.constant },
    ["@comment"] = { fg = theme.syntax.comment, italic = true },
    ["@operator"] = { fg = theme.syntax.operator },
    ["@markup.heading"] = { fg = theme.accent.primary, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = theme.semantic.error, bold = true },
    DiagnosticWarn = { fg = theme.semantic.warning, bold = true },
    DiagnosticInfo = { fg = theme.semantic.info, bold = true },
    DiagnosticHint = { fg = theme.accent.secondary, bold = true },

    -- Neogit & Diff
    DiffAdd = { bg = bg_sec, fg = theme.diff.add },
    DiffChange = { bg = bg_sec, fg = theme.diff.change },
    DiffDelete = { bg = bg_sec, fg = theme.diff.delete },
    NeogitDiffAdd = { bg = bg_sec, fg = theme.diff.add },
    NeogitDiffDelete = { bg = bg_sec, fg = theme.diff.delete },
    NeogitDiffContext = { bg = bg_val, fg = c.base05 },

    -- NeoTree
    NeoTreeNormal = { bg = bg_val, fg = c.base05 },
    NeoTreeNormalNC = { bg = bg_val, fg = c.base05 },
    NeoTreeRootName = { fg = theme.accent.primary, bold = true },
    NeoTreeDirectoryName = { fg = c.base05 },
    NeoTreeFileNameOpened = { fg = theme.accent.primary, bold = true },
    NeoTreeWinSeparator = { fg = c.base03, bold = true },

    -- GitSigns
    GitSignsAdd = { fg = theme.diff.add, bold = true },
    GitSignsChange = { fg = theme.diff.change, bold = true },
    GitSignsDelete = { fg = theme.diff.delete, bold = true },

    -- Telescope
    TelescopeNormal = { bg = bg_val },
    TelescopeBorder = { bg = "NONE", fg = c.base03 },
    TelescopePromptPrefix = { fg = theme.accent.primary, bold = true },
    TelescopeSelection = { fg = theme.semantic.error, bold = true },

    -- LSP & Completion (Blink/Wilder)
    BlinkCmpMenu = { bg = bg_val },
    BlinkCmpMenuBorder = { bg = "NONE", fg = c.base03 },
    WilderSelected = { fg = theme.accent.primary, bold = true },
    WilderAccent = { fg = theme.accent.primary, bold = true },
    StatusLine = { bg = bg_val, fg = c.base05 },
    StatusLineNC = { bg = bg_val, fg = c.base03 },
    WinBar = { bg = bg_val, fg = c.base05 },
  }

  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

-- Initial apply on startup
apply_theme()

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_theme,
  desc = "Sync semantic highlights and transparency",
})

vim.api.nvim_create_user_command("TransparencyToggle", function()
  vim.g.transparency_user_override = not (vim.g.transparency_user_override or false)
  -- Re-read the colors and re-apply
  apply_theme()
  print("Transparency: " .. (vim.g.transparency_user_override and "ON" or "OFF"))
end, { desc = "Toggle transparency" })

vim.api.nvim_create_user_command("Colorscheme", function()
  require("snacks").picker.colorschemes({ on_close = apply_theme })
end, { desc = "Picker for colorschemes" })
