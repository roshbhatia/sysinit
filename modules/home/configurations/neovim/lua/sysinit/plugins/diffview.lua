return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    cmd = {
      "DiffviewOpen",
    },
    config = function()
      require("diffview").setup({
        default_args = {
          DiffviewOpen = { "--imply-local" },
        },
        hooks = {
          diff_buf_read = function(bufnr)
            vim.diagnostic.disable(bufnr)
            vim.opt_local.list = false
            vim.opt_local.relativenumber = false
            vim.opt_local.wrap = false
          end,
        },
        view = {
          merge_tool = {
            layout = "diff3_mixed",
          },
        },
      })
    end,
    keys = {
      {
        "<leader>dd",
        "<Cmd>DiffviewOpen<CR>",
        desc = "Open diffview",
      },
      {
        "<leader>dh",
        "<Cmd>DiffviewFileHistory %<CR>",
        desc = "File history",
      },
      {
        "<leader>dH",
        "<Cmd>DiffviewFileHistory<CR>",
        desc = "Branch history",
      },
      {
        "<leader>dc",
        "<Cmd>DiffviewClose<CR>",
        desc = "Close diffview",
      },
    },
  },
}
