local highlight_gen = require("sysinit.plugins.ui.themes.highlight_generator")

local M = {}

function M.apply(theme_config)
  local overrides = highlight_gen.generate_core_highlights(theme_config.transparency)

  local manual_overrides = {
    -- UI & Gutter
    CursorLineNr = { link = "CursorLineNr" }, -- Already standard, but ensures it's kept
    LineNr = { link = "LineNr" },

    -- Diffs (Standard Neovim groups)
    DiffAdd = { link = "DiffAdd" },
    DiffChange = { link = "DiffChange" },
    DiffDelete = { link = "DiffDelete" },

    -- Floats & Menus
    FloatBorder = { link = "Comment" },
    FloatTitle = { link = "Title" },
    NormalFloat = { link = "Normal" },
    Pmenu = { link = "Normal" },
    PmenuSel = { link = "Visual" },
    PmenuSbar = { link = "PmenuSbar" },
    PmenuThumb = { link = "PmenuThumb" },

    -- Search
    Search = { link = "Search" },
    IncSearch = { link = "IncSearch" },

    -- Windows & Status
    StatusLine = { link = "StatusLine" },
    StatusLineNC = { link = "StatusLineNC" },
    WinSeparator = { link = "VertSplit" },
    WinBar = { link = "StatusLine" },
    WinBarNC = { link = "StatusLineNC" },

    -- Diagnostics (Linking to standard LSP diagnostic groups)
    DiagnosticError = { link = "ErrorMsg" },
    DiagnosticWarn = { link = "WarningMsg" },
    DiagnosticInfo = { link = "Identifier" },
    DiagnosticHint = { link = "Comment" },

    DiagnosticVirtualLinesError = { link = "DiagnosticError" },
    DiagnosticVirtualLinesWarn = { link = "DiagnosticWarn" },
    DiagnosticVirtualLinesInfo = { link = "DiagnosticInfo" },
    DiagnosticVirtualLinesHint = { link = "DiagnosticHint" },

    -- Git (Neogit specific links to Diff groups)
    NeogitDiffAdd = { link = "DiffAdd" },
    NeogitDiffDelete = { link = "DiffDelete" },
    NeogitDiffContextHighlight = { link = "CursorLine" },

    -- Neo-tree (Linking to Sidebar/UI defaults)
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
