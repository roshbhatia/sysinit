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
    plugins = {
      marks = true,
      registers = true,
      spelling = {
        enabled = false,
      },
      presets = {
        operators = true,
        motions = true,
        text_objects = true,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },
    triggers_nowait = {
      -- commands
      "`",
      "'",
      "g`",
      "g'",
      '"',
      "<c-r>",
      "z=",
    }
  })
end

return M
