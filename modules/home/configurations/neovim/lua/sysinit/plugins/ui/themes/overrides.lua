local highlight_gen = require("sysinit.plugins.ui.themes.highlight_generator")

local M = {}

function M.apply(theme_config)
  local overrides = highlight_gen.generate_core_highlights(theme_config.transparency)

  local manual_overrides = {
    -- Floats & Menus
    FloatBorder = { link = "Comment" },
    FloatTitle = { link = "Title" },
    NormalFloat = { link = "Normal" },
    Pmenu = { link = "Normal" },
    PmenuSel = { link = "Visual" },

    -- Windows & Status
    WinSeparator = { link = "VertSplit" },
    WinBar = { link = "StatusLine" },
    WinBarNC = { link = "StatusLineNC" },

    -- Diagnostics
    DiagnosticError = { link = "ErrorMsg" },
    DiagnosticWarn = { link = "WarningMsg" },
    DiagnosticInfo = { link = "Identifier" },
    DiagnosticHint = { link = "Comment" },

    DiagnosticVirtualLinesError = { link = "DiagnosticError" },
    DiagnosticVirtualLinesWarn = { link = "DiagnosticWarn" },
    DiagnosticVirtualLinesInfo = { link = "DiagnosticInfo" },
    DiagnosticVirtualLinesHint = { link = "DiagnosticHint" },

    -- Git (Neogit)
    NeogitDiffAdd = { link = "DiffAdd" },
    NeogitDiffDelete = { link = "DiffDelete" },
    NeogitDiffContextHighlight = { link = "CursorLine" },

    -- Neo-tree
    NeoTreeNormal = { link = "Normal" },
    NeoTreeDirectoryIcon = { link = "Directory" },
    NeoTreeDirectoryName = { link = "Directory" },
    NeoTreeFileName = { link = "Normal" },
    NeoTreeCursorLine = { link = "CursorLine" },
    NeoTreeGitAdded = { link = "DiffAdd" },
    NeoTreeGitModified = { link = "DiffChange" },
    NeoTreeGitDeleted = { link = "DiffDelete" },
    NeoTreeIndentMarker = { link = "NonText" },
    NeoTreeExpander = { link = "Comment" },

    -- Wilder / Completion
    WilderSelected = { link = "PmenuSel" },
    WilderAccent = { link = "Keyword" },
  }

  -- Merge overrides
  for group, opts in pairs(manual_overrides) do
    overrides[group] = opts
  end

  -- Apply to Neovim
  for name, hl in pairs(overrides) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

return M
