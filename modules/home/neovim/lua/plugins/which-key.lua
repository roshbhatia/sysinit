return {
  {
    "folke/which-key.nvim",
    config = function()
      local wk = require("which-key")
      wk.setup({
        plugins = {
          spelling = { enabled = true },
        },
        win = { -- Updated from `window` to `win`
          border = "rounded",
        },
      })

      wk.add({
        { "<leader>", group = "Leader" }, 
        { "<leader>f", group = "Leader" }, 
        { "<leader>w", group = "Windows" }, 
      })
    end,
  },
}