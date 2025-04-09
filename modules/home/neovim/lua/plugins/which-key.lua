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

      -- Add keybinding groups inline
      wk.add({
        { "<leader>", group = "Leader" },
        { "<leader>w", group = "Windows" },
        { "<leader>f", group = "Files" },
        { "<leader>g", group = "Git" },
        { "<leader>x", group = "Diagnostics" },
        { "<leader>s", group = "Sessions" }, -- Added session management group
      })
    end,
  },
}