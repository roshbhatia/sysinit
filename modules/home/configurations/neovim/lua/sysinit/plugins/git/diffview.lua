local M = {}

M.plugins = {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    config = function()
      local actions = require("diffview.actions")

      require("diffview").setup({
        enhanced_diff_hl = true,
        view = {
          default = {
            winbar_info = true,
          },
          merge_tool = {
            layout = "diff3_mixed",
          },
          file_history = {
            layout = "diff2_vertical",
            winbar_info = true,
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

        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                diff_merges = "combined",
              },
              multi_file = {
                diff_merges = "first-parent",
              },
            },
          },
          win_config = {
            position = "bottom",
            height = 16,
          },
        },

        hooks = {
          diff_buf_read = function(bufnr)
            vim.opt_local.wrap = false
            vim.opt_local.list = false
            vim.opt_local.colorcolumn = ""
          end,
        },

        keymaps = {
          view = {
            { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
            { "n", "<esc>", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
            { "n", "<localleader>l", actions.cycle_layout, { desc = "Cycle layout" } },
          },
          file_panel = {
            { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
            { "n", "<esc>", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
            { "n", "<localleader>l", actions.cycle_layout, { desc = "Cycle layout" } },
          },
          file_history_panel = {
            { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
            { "n", "<esc>", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
            { "n", "<localleader>l", actions.cycle_layout, { desc = "Cycle layout" } },
          },
        },
      })
    end,
    keys = {
      {
        "<leader>gv",
        function()
          local lib = require("diffview.lib")
          local view = lib.get_current_view()
          if view then
            vim.cmd("DiffviewClose")
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Toggle Diffview",
      },
      {
        "<leader>gh",
        "<cmd>DiffviewFileHistory %<CR>",
        desc = "File history (current)",
      },
      {
        "<leader>gH",
        "<cmd>DiffviewFileHistory<CR>",
        desc = "File history (all)",
      },
    },
  },
}

return M
