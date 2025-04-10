local M = {}

function M.setup()
  require("which-key").setup({
    win = { 
      border = "rounded",
      width = 0.8,
      height = 0.6,
    },
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
    },
    triggers = {
      -- Blacklist specific keys in insert and visual modes
      { mode = "i", keys = "j" },
      { mode = "i", keys = "k" },
      { mode = "v", keys = "j" },
      { mode = "v", keys = "k" },
    }
  })
end

return M
