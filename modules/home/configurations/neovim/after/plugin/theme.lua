if not vim.g.nix_managed then
  vim.cmd.colorscheme("base16-tokyo-city-terminal-light")
end

local c = require("base16-colorscheme").colors

-- Semantic Roles
local theme = {
  bg = c.base00,
  bg_sub = c.base01,
  sel = c.base02,
  comment = c.base03,
  fg_sub = c.base04,
  fg = c.base05,
  accent = c.base0D,
  special = c.base0E,
  error = c.base08,
  warn = c.base0A,
  info = c.base0C,
  hint = c.base03,
  success = c.base0B,
}

local function apply_theme()
  local transparency = (vim.g.transparency_user_override ~= nil) and vim.g.transparency_user_override
    or (vim.g.nix_transparency_enabled or false)

  local real_bg = transparency and "NONE" or theme.bg

  local hls = {
    -- Core UI
    Normal = { fg = theme.fg, bg = real_bg },
    NormalNC = { fg = theme.fg, bg = real_bg },
    SignColumn = { fg = theme.comment, bg = "NONE" },
    CursorLine = { bg = theme.bg_sub },
    CursorLineNr = { fg = theme.accent, bold = true },
    LineNr = { fg = theme.comment },
    Visual = { bg = theme.sel },
    Search = { fg = theme.bg, bg = theme.warn },
    IncSearch = { fg = theme.bg, bg = c.base09 },
    Question = { fg = theme.accent },
    WilderAccent = { fg = theme.accent, bold = true },

    -- Status & Windows
    StatusLine = { fg = theme.fg, bg = transparency and "NONE" or theme.bg_sub },
    StatusLineNC = { fg = theme.fg_sub, bg = transparency and "NONE" or theme.bg_sub },
    WinSeparator = { fg = theme.bg_sub, bold = true },
    FloatBorder = { fg = theme.comment, bg = "NONE" },
    NormalFloat = { fg = theme.fg, bg = "NONE" },

    -- TreeSitter / Syntax roles
    ["@variable"] = { fg = c.base08 },
    ["@variable.builtin"] = { fg = c.base08, italic = true },
    ["@function"] = { fg = c.base0D },
    ["@function.builtin"] = { fg = c.base0D, italic = true },
    ["@keyword"] = { fg = c.base0E, bold = true },
    ["@operator"] = { fg = theme.fg },
    ["@punctuation"] = { fg = c.base0F },
    ["@string"] = { fg = c.base0B },
    ["@number"] = { fg = c.base09 },
    ["@constant"] = { fg = c.base09 },
    ["@type"] = { fg = c.base0A },
    ["@comment"] = { fg = theme.comment, italic = true },
    ["@markup.heading"] = { fg = theme.accent, bold = true },
    ["@markup.link.url"] = { fg = c.base09, underline = true },

    -- Diagnostics
    DiagnosticError = { fg = theme.error },
    DiagnosticWarn = { fg = theme.warn },
    DiagnosticInfo = { fg = theme.info },
    DiagnosticHint = { fg = theme.hint },
  }

  -- 4. Apply Initial Groups
  for name, opts in pairs(hls) do
    vim.api.nvim_set_hl(0, name, opts)
  end

  local links = {
    -- Neogit
    NeogitBranch = "@function",
    NeogitRemote = "@constant",
    NeogitHunkHeader = "CursorLine",
    NeogitHunkHeaderHighlight = "Visual",
    NeogitDiffAdd = "DiagnosticOk",
    NeogitDiffDelete = "DiagnosticError",

    -- NeoTree
    NeoTreeNormal = "Normal",
    NeoTreeNormalNC = "Normal",
    NeoTreeRootName = "@function",
    NeoTreeDirectoryName = "Directory",
    NeoTreeFileNameOpened = "Special",

    -- Completion (Blink / Cmp)
    BlinkCmpMenu = "Pmenu",
    BlinkCmpMenuBorder = "FloatBorder",
    BlinkCmpDoc = "NormalFloat",
    BlinkCmpDocBorder = "FloatBorder",

    -- Telescope
    TelescopeNormal = "NormalFloat",
    TelescopeBorder = "FloatBorder",
    TelescopeSelection = "Visual",

    -- GitSigns
    GitSignsAdd = "DiagnosticOk",
    GitSignsChange = "DiagnosticWarn",
    GitSignsDelete = "DiagnosticError",
  }

  for from, to in pairs(links) do
    vim.api.nvim_set_hl(0, from, { link = to })
  end
end

apply_theme()

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_theme,
  desc = "Re-apply dynamic semantic mapping",
})

vim.api.nvim_create_user_command("TransparencyToggle", function()
  vim.g.transparency_user_override = not (vim.g.transparency_user_override or false)
  apply_theme()
  print("Transparency: " .. (vim.g.transparency_user_override and "ON" or "OFF"))
end, {})
