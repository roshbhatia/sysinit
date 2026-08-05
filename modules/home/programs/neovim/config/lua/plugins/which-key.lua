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
        { "<leader>cf", group = "Find" },
        { "<leader>d", group = "Diff" },
        { "<leader>dr", group = "Review" },
        { "<leader>e", group = "Explorer" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>gb", group = "Buffer" },
        { "<leader>gf", group = "Find" },
        { "<leader>gh", group = "Hunk" },
        { "<leader>j", group = "Agents" },
        { "<leader>q", group = "Force Quit" },
        { "<leader>t", group = "Terminal" },
        { "[", group = "Prev" },
        { "]", group = "Next" },
        { "gr", group = "LSP" },
        { "v<leader>", group = "Extras" },
        { "v<leader>c", group = "Code" },
        { "v<leader>g", group = "Git" },
        { "v<leader>j", group = "Agents" },
        { "vg", group = "Extras" },
        { "vgr", group = "Code" },
        { "vv", group = "AST" },
        { "vz", group = "Fold" },
      })
    end,
  },
}
