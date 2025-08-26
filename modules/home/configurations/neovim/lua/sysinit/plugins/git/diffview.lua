local M = {}

M.plugins = {
  {
    "sindrets/diffview.nvim",
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = true,
      })
    end,
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    keys = function()
      return {
        {
          "<leader>gd",
          function()
            vim.cmd("DiffviewOpen")
          end,
          desc = "Git: Open diff view",
          mode = "n",
        },
        {
          "<leader>gD",
          function()
            vim.cmd("DiffviewClose")
          end,
          desc = "Git: Close diff view",
          mode = "n",
        },
        {
          "<leader>gh",
          function()
            vim.cmd("DiffviewFileHistory %")
          end,
          desc = "Git: File history (current file)",
          mode = "n",
        },
        {
          "<leader>gH",
          function()
            vim.cmd("DiffviewFileHistory")
          end,
          desc = "Git: File history (project)",
          mode = "n",
        },
        {
          "<leader>gf",
          function()
            vim.cmd("DiffviewFocusFiles")
          end,
          desc = "Git: Focus file panel",
          mode = "n",
        },
        {
          "<leader>gt",
          function()
            vim.cmd("DiffviewToggleFiles")
          end,
          desc = "Git: Toggle file panel",
          mode = "n",
        },
        {
          "<leader>gr",
          function()
            vim.cmd("DiffviewRefresh")
          end,
          desc = "Git: Refresh diff view",
          mode = "n",
        },
      }
    end,
  },
}

return M
