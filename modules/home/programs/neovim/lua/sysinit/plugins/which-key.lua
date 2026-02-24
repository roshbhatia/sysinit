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
        win = {
          border = "rounded",
        },
        layout = {
          spacing = 6,
          align = "center",
        },
      })

      wk.add({
        { "<leader>c", group = "Code" },
        { "<leader>cf", group = "Find" },
        { "<leader>d", group = "Diff" },
        { "<leader>e", group = "Editor" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>gb", group = "Buffer" },
        { "<leader>gh", group = "Hunk" },
        { "<leader>gf", group = "Find" },
        { "<leader>j", group = "AI Agents" },
        { "<localleader>x", group = "Filetype Specific" },
        { "<leader>m", group = "Marks" },
        { "<leader>r", group = "Debug" },
        { "gr", group = "LSP" },
      })
    end,
  },
}
