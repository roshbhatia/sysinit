return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("diffview").setup({
        default_args = {
          DiffviewOpen = { "--imply-local" },
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
        desc = "Diff against index",
      },
      {
        "<leader>dm",
        function()
          vim.fn.system("git rev-parse --verify main 2>/dev/null")
          if vim.v.shell_error == 0 then
            vim.cmd("DiffviewOpen main")
          else
            vim.cmd("DiffviewOpen master")
          end
        end,
        desc = "Diff against default branch",
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
