local M = {}

function M.setup(transparency)
  local config = {
    transparent = transparency.transparent_background,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = { bold = true },
      variables = {},
      constants = { bold = true },
      types = { bold = true },
    },
    on_highlights = function(highlights, colors)
      local bg = transparency.transparent_background and colors.none or colors.base03
      highlights.Normal = { bg = bg, fg = colors.base0 }
      highlights.NormalNC = { bg = bg }
      highlights.SignColumn = { bg = bg }
      highlights.CursorLine = { bg = colors.none }
      highlights.Visual = { bg = colors.base02, fg = colors.base1, bold = true }
    end,
  }

  require("solarized-osaka").setup(config)
end

function M.get_transparent_highlights()
  return {
    Normal = { bg = "none" },
    NormalNC = { bg = "none" },
    SignColumn = { bg = "none" },
    CursorLine = { bg = "none" },
  }
end

return M
