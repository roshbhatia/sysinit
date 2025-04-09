-- Diffview.nvim configuration (VSCode-like merge editor)
return {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen", 
      "DiffviewClose", 
      "DiffviewToggleFiles", 
      "DiffviewFocusFiles",
      "DiffviewFileHistory"
    },
    keys = {
      { "<leader>gd", ":DiffviewOpen<CR>", desc = "Open Diffview" },
      { "<leader>gh", ":DiffviewFileHistory<CR>", desc = "Open file history" },
      { "<leader>gc", ":DiffviewClose<CR>", desc = "Close Diffview" },
    },
    config = function()
      local actions = require("diffview.actions")
      
      require("diffview").setup({
        diff_binaries = false,
        enhanced_diff_hl = true,
        git_cmd = { "git" },
        use_icons = true,
        icons = {
          folder_closed = "",
          folder_open = "",
        },
        signs = {
          fold_closed = "",
          fold_open = "",
          done = "✓",
        },
        view = {
          default = {
            winbar_info = true,
            layout = "diff2_horizontal",
          },
          merge_tool = {
            layout = "diff3_mixed",
            disable_diagnostics = true,
            winbar_info = true,
          },
          file_history = {
            layout = "diff2_horizontal",
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
            win_opts = {},
          },
        },
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                max_count = 512,
                follow = true,
              },
              multi_file = {
                max_count = 128,
              },
            },
          },
          win_config = {
            position = "bottom",
            height = 16,
            win_opts = {},
          },
        },
        default_args = {
          DiffviewOpen = {},
          DiffviewFileHistory = {},
        },
        hooks = {},
        keymaps = {
          disable_defaults = false,
          view = {
            ["<tab>"] = actions.select_next_entry,
            ["<s-tab>"] = actions.select_prev_entry,
            ["<leader>e"] = actions.focus_files,
            ["<leader>b"] = actions.toggle_files,
            ["q"] = actions.close,
            ["gf"] = actions.goto_file_edit,
          },
          file_panel = {
            ["j"] = actions.next_entry,
            ["k"] = actions.prev_entry,
            ["<cr>"] = actions.select_entry,
            ["o"] = actions.select_entry,
            ["R"] = actions.refresh_files,
            ["<tab>"] = actions.select_next_entry,
            ["<s-tab>"] = actions.select_prev_entry,
            ["q"] = actions.close,
            ["?"] = actions.help("file_panel"),
          },
          file_history_panel = {
            ["g!"] = actions.options,
            ["<C-d>"] = actions.scroll_view(0.25),
            ["<C-u>"] = actions.scroll_view(-0.25),
            ["j"] = actions.next_entry,
            ["k"] = actions.prev_entry,
            ["<cr>"] = actions.select_entry,
            ["o"] = actions.select_entry,
            ["q"] = actions.close,
            ["?"] = actions.help("file_history_panel"),
          },
          option_panel = {
            ["<tab>"] = actions.select_entry,
            ["q"] = actions.close,
          },
          help_panel = {
            ["q"] = actions.close,
            ["<esc>"] = actions.close,
          },
        },
      })
    end,
  }
}
