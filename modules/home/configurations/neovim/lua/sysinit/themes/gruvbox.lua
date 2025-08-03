local M = {}

function M.setup(transparency)
  local config = {
    terminal_colors = true,
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
      strings = true,
      emphasis = true,
      comments = true,
      operators = false,
      folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true,
    contrast = "hard",
    palette_overrides = {},
    overrides = {},
    dim_inactive = false,
    transparent_mode = transparency.transparent_background,
  }

  require("gruvbox").setup(config)
end

function M.get_transparent_highlights()
  return {
    Normal = { bg = "none" },
    NormalNC = { bg = "none" },
    SignColumn = { bg = "none" },
    CursorLine = { bg = "none" },
    StatusLine = { bg = "none" },
    StatusLineNC = { bg = "none" },
  }
end

return M
