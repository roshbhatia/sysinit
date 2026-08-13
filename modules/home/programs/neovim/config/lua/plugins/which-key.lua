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
        { "<leader>dn", group = "Notes" },
        -- No group on `<leader>dd`: a group and a mapping cannot share a sequence, and
        -- declaring one made which-key present the review as a prefix waiting for a key.
        { "<leader>e", group = "Explorer" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>gb", group = "Buffer" },
        { "<leader>gh", group = "Hunk" },
        { "<leader>j", group = "Agents" },
        { "<leader>q", group = "Force Quit" },
        { "[", group = "Prev" },
        { "]", group = "Next" },
        { "gr", group = "LSP" },
        -- Visual mode is `mode`, not a `v` prefix on the sequence. Written as `v<leader>c`
        -- these named a normal-mode `v` then `<leader>c`, which nothing maps.
        { "<leader>f", group = "Find", mode = "v" },
        { "<leader>g", group = "Git", mode = "v" },
        { "<leader>gh", group = "Hunk", mode = "v" },
        { "<leader>j", group = "Agents", mode = "v" },
      })
    end,
  },
}
