return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = true,
        use_icons = true,
        show_help_hints = true,
        view = {
          default = {
            layout = "diff2_horizontal",
          },
          merge_tool = {
            layout = "diff3_horizontal",
          },
          file_history = {
            layout = "diff2_horizontal",
          },
        },
        file_panel = {
          listing_style = "tree",
          tree_options = {
            flatten_dirs = true,
            folder_statuses = "only_folded",
          },
          win_config = {
            position = "left",
            width = 35,
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
        desc = "Diff against main/master",
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
