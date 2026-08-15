return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")

      wk.setup({
        preset = "helix",
        icons = {
          mappings = false,
          separator = " ",
        },
        notify = false,
        layout = {
          spacing = 6,
          align = "center",
        },
      })

      wk.add({
        { "<leader>c", group = "Code" },
        { "<leader>cf", group = "Search" },
        { "<leader>d", group = "Diff" },
        { "<leader>dn", group = "Notes" },
        { "<leader>e", group = "Explorer" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>gb", group = "Buffer" },
        { "<leader>gh", group = "Hunk" },
        { "<leader>j", group = "Agents" },
        { "[", group = "Prev" },
        { "]", group = "Next" },
        { "gr", group = "LSP" },
        { "<leader>f", group = "Find", mode = "v" },
        { "<leader>g", group = "Git", mode = "v" },
        { "<leader>gh", group = "Hunk", mode = "v" },
        { "<leader>j", group = "Agents", mode = "v" },
      })
    end,
  },
}
