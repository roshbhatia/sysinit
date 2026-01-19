return {
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    cmd = "Neotree",
    config = function()
      require("window-picker").setup({
        hint = "floating-big-letter",
        show_prompt = false,
        picker_config = {
          handle_mouse_click = true,
        },
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "folke/snacks.nvim",
    },
    config = function()
      vim.g.neo_tree_remove_legacy_commands = 1

      local events = require("neo-tree.events")

      require("neo-tree").setup({
        close_if_last_window = true,
        enable_diagnostics = true,
        enable_modified_markers = false,
        enable_opened_markers = false,
        sort_case_insensitive = true,
        auto_clean_after_session_restore = true,
        sources = { "filesystem" },
        default_component_configs = {
          indent = {
            with_expanders = true,
            with_markers = false,
          },
          icon = {
            folder_closed = "",
            folder_open = "",
          },
          name = {
            use_git_status_colors = true,
          },
          git_status = {
            symbols = {
              added = "+",
              deleted = "-",
              modified = "~",
              renamed = "",
              untracked = "",
              ignored = "",
              unstaged = "",
              staged = "",
              conflict = "",
            },
          },
        },

        window = {
          mappings = {
            ["<2-LeftMouse>"] = "open",
            ["<CR>"] = "open",
            ["<esc>"] = "revert_preview",
            ["P"] = { "toggle_preview", config = { use_float = false } },
            ["s"] = "open_split",
            ["v"] = "open_vsplit",
            ["z"] = "close_all_nodes",
            ["Z"] = "expand_all_nodes",
            ["a"] = { "add", config = { show_path = "none" } },
            ["d"] = "delete",
            ["r"] = "rename",
            ["y"] = "copy_to_clipboard",
            ["x"] = "cut_to_clipboard",
            ["p"] = "paste_from_clipboard",
            ["c"] = "copy",
            ["m"] = "move",
            ["q"] = "close_window",
            ["?"] = "show_help",
            ["<localleader>p"] = "prev_source",
            ["<localleader>n"] = "next_source",
          },
        },
        filesystem = {
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
          find_command = "fd",
          find_args = {
            fd = {
              "--hidden",
              "--exclude",
              ".git",
              "--exclude",
              "node_modules",
            },
          },
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
            never_show = { ".DS_Store" },
          },
          event_handlers = {
            {
              event = events.FILE_MOVED,
              handler = function(data)
                Snacks.rename.on_rename_file(data.source, data.destination)
              end,
            },
            {
              event = events.FILE_RENAMED,
              handler = function(data)
                Snacks.rename.on_rename_file(data.source, data.destination)
              end,
            },
          },
        },
      })
    end,
    keys = {
      {
        "<leader>et",
        function()
          vim.cmd("Neotree toggle")
          vim.cmd("wincmd p")
        end,
        desc = "Toggle explorer tree",
      },
    },
  },
}
