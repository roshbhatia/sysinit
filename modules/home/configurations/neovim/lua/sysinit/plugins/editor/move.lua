local M = {}

M.plugins = {
  {
    "echasnovski/mini.move",
    version = "*",
    config = function()
      require("mini.move").setup({
        mappings = {
          -- Move visual selection in Visual mode. Use Shift + hjkl.
          left = "<S-h>",
          right = "<S-l>",
          down = "<S-j>",
          up = "<S-k>",
        },
        options = {
          reindent_linewise = true,
        },
      })
    end,
  },
}

return M
