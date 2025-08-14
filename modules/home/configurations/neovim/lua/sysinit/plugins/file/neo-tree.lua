local M = {}

local function get_palette_colors()
  local variable = vim.api.nvim_get_hl(0, { name = "@variable", link = false })
  local root = vim.api.nvim_get_hl(0, { name = "Directory", link = false })
  local message = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  return {
    file = variable and variable.fg and string.format("#%06x", variable.fg) or "#606377",
    root = root and root.fg and string.format("#%06x", root.fg) or "#606377",
    message = message and message.fg and string.format("#%06x", message.fg) or "#606377",
  }
end

M.plugins = {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    event = "BufReadPre",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "folke/snacks.nvim",
    },
    config = function()
      vim.g.neo_tree_remove_legacy_commands = 1

      require("neo-tree").setup({
        open_files_do_not_replace_types = { "terminal", "Trouble", "qf", "edgy" },
        event_handlers = {
          {
            event = "neo_tree_buffer_enter",
            handler = function(arg)
              vim.opt_local.statuscolumn = "%s"
              vim.opt_local.number = false
              vim.opt_local.relativenumber = false
              vim.opt_local.wrap = true
              vim.opt_local.sidescrolloff = 0
            end,
          },
        },
        enable_modified_markers = false,
        enable_opened_markers = false,
        close_if_last_window = true,
        enable_diagnostics = true,
        sort_case_insensitive = true,
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
              added = "",
              deleted = "",
              modified = "",
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
            ["P"] = {
              "toggle_preview",
              config = {
                use_float = true,
              },
            },
            ["s"] = "open_split",
            ["v"] = "open_vsplit",
            ["z"] = "close_all_nodes",
            ["Z"] = "expand_all_nodes",
            ["a"] = {
              "add",
              config = {
                show_path = "none",
              },
            },
            ["d"] = "delete",
            ["r"] = "rename",
            ["y"] = "copy_to_clipboard",
            ["x"] = "cut_to_clipboard",
            ["p"] = "paste_from_clipboard",
            ["c"] = "copy",
            ["m"] = "move",
            ["q"] = "close_window",
            ["?"] = "show_help",
            ["<"] = "prev_source",
            [">"] = "next_source",
          },
        },
        filesystem = {
          commands = {
            ai_add_to_goose = function(state)
              local node = state.tree:get_node()
              local filepath = node:get_id()
              require("ai-terminals").add_files_to_terminal("goose", { filepath })
              vim.notify("Added " .. vim.fn.fnamemodify(filepath, ":t") .. " to Goose")
            end,
            ai_add_to_claude = function(state)
              local node = state.tree:get_node()
              local filepath = node:get_id()
              require("ai-terminals").add_files_to_terminal("claude", { filepath })
              vim.notify("Added " .. vim.fn.fnamemodify(filepath, ":t") .. " to Claude")
            end,
            ai_add_to_opencode = function(state)
              local node = state.tree:get_node()
              local filepath = node:get_id()
              require("ai-terminals").add_files_to_terminal("opencode", { filepath })
              vim.notify("Added " .. vim.fn.fnamemodify(filepath, ":t") .. " to OpenCode")
            end,
          },
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            never_show = {
              ".DS_Store",
              ".git",
              "node_modules",
              ".direnv",
            },
            visible = true,
          },
          follow_current_file = {
            enabled = true,
          },
          use_libuv_file_watcher = true,
          event_handlers = function()
            local function on_move(data)
              Snacks.rename.on_rename_file(data.source, data.destination)
            end
            return {
              {
                event = require("neo-tree.events").FILE_MOVED,
                handler = on_move,
              },
              {
                event = require("neo-tree.events").FILE_RENAMED,
                handler = on_move,
              },
            }
          end,
          window = {
            mappings = {
              ["+g"] = "ai_add_to_goose",
              ["+c"] = "ai_add_to_claude",
              ["+o"] = "ai_add_to_opencode",
            },
          },
          find_command = "fd",
          find_args = {
            fd = {
              "--hidden",
              "--exclude",
              ".git/",
              "--exclude",
              ".git/",
              "--exclude",
              ".direnv/",
              "node_modules/",
            },
          },
        },
      })

      local colors = get_palette_colors()
      vim.api.nvim_set_hl(0, "NeoTreeFileName_35", { fg = colors.file, bg = nil, bold = true })
      vim.api.nvim_set_hl(0, "NeoTreeRootName_35", { fg = colors.root, bg = nil, bold = true })
      vim.api.nvim_set_hl(0, "NeoTreeMessage", { fg = colors.message, bg = nil, bold = false })
    end,
    keys = {
      {
        "<leader>et",
        function()
          vim.cmd("Neotree toggle")
          vim.cmd("wincmd p")
        end,
        desc = "Toggle file tree",
      },
    },
  },
}

return M
