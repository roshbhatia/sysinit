local M = {}

M.plugins = {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    lazy = false,
    dependencies = {
      "debugloop/telescope-undo.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-dap.nvim",
      "nvim-telescope/telescope-fzy-native.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-tree/nvim-web-devicons",
      "olimorris/persisted.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local themes = require("telescope.themes")

      -- Custom actions for ai-terminals integration
      local function add_files_to_goose(prompt_bufnr)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local multi_selection = current_picker:get_multi_selection()
        local files = {}

        if #multi_selection > 0 then
          for _, entry in ipairs(multi_selection) do
            table.insert(files, entry.filename or entry.value)
          end
        else
          local selection = action_state.get_selected_entry()
          if selection then
            table.insert(files, selection.filename or selection.value)
          end
        end

        actions.close(prompt_bufnr)
        if #files > 0 then
          require("ai-terminals").add_files_to_terminal("goose", files)
          vim.notify("Added " .. #files .. " file(s) to Goose")
        end
      end

      local function add_files_to_claude(prompt_bufnr)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local multi_selection = current_picker:get_multi_selection()
        local files = {}

        if #multi_selection > 0 then
          for _, entry in ipairs(multi_selection) do
            table.insert(files, entry.filename or entry.value)
          end
        else
          local selection = action_state.get_selected_entry()
          if selection then
            table.insert(files, selection.filename or selection.value)
          end
        end

        actions.close(prompt_bufnr)
        if #files > 0 then
          require("ai-terminals").add_files_to_terminal("claude", files)
          vim.notify("Added " .. #files .. " file(s) to Claude")
        end
      end

      local function add_files_to_opencode(prompt_bufnr)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local multi_selection = current_picker:get_multi_selection()
        local files = {}

        if #multi_selection > 0 then
          for _, entry in ipairs(multi_selection) do
            table.insert(files, entry.filename or entry.value)
          end
        else
          local selection = action_state.get_selected_entry()
          if selection then
            table.insert(files, selection.filename or selection.value)
          end
        end

        actions.close(prompt_bufnr)
        if #files > 0 then
          require("ai-terminals").add_files_to_terminal("opencode", files)
          vim.notify("Added " .. #files .. " file(s) to OpenCode")
        end
      end

      telescope.setup({
        defaults = {
          prompt_prefix = "   ",
          selection_caret = "",
          entry_prefix = "",
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          results_title = "",
          prompt_title = "",
          preview_title = "",
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
            },
            width = 0.87,
            height = 0.80,
          },
          mappings = {
            n = {
              ["q"] = actions.close,
              ["<Tab>"] = actions.move_selection_next,
              ["<S-Tab>"] = actions.move_selection_previous,
              ["j"] = actions.move_selection_next,
              ["k"] = actions.move_selection_previous,
              ["<Down>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
              ["<CR>"] = actions.select_default,
              ["<localleader>s"] = actions.select_horizontal,
              ["<localleader>v"] = actions.select_vertical,
              ["<localleader>t"] = actions.select_tab,
              -- AI Terminal actions
              ["<localleader>g"] = add_files_to_goose,
              ["<localleader>c"] = add_files_to_claude,
              ["<localleader>o"] = add_files_to_opencode,
            },
            i = {
              ["<Tab>"] = actions.move_selection_next,
              ["<S-Tab>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<Down>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
              ["<CR>"] = actions.select_default,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,
              -- AI Terminal actions (same as normal mode)
              ["<C-g>"] = add_files_to_goose,
              ["<C-c>"] = add_files_to_claude,
              ["<C-o>"] = add_files_to_opencode,
            },
          },
          file_ignore_patterns = {
            "^%.git/",
            "%.cache",
            "%.png",
            "%.jpg",
            "%.jpeg",
            "%.o",
            ".cache",
            "Build",
          },
        },
        extensions = {
          ["ui-select"] = {
            themes.get_dropdown(),
          },
          persisted = {
            layout_config = { width = 0.55, height = 0.55 },
          },
          fzy_native = {
            override_generic_sorter = true,
            override_file_sorter = true,
          },
          dap = {},
          live_grep_args = {},
          undo = {
            side_by_side = true,
            layout_strategy = "vertical",
            layout_config = {
              preview_height = 0.8,
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
          live_grep = {
            additional_args = function()
              return { "--hidden" }
            end,
          },
          colorscheme = {
            enable_preview = true,
          },
        },
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--hidden",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--trim",
        },
      })

      local function lazy_load_ext(ext)
        local ok, _ = pcall(telescope.load_extension, ext)
        if not ok then
          return
        end
      end
      vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopeFindFiles",
        callback = function()
          lazy_load_ext("fzy_native")
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopeLiveGrep",
        callback = function()
          lazy_load_ext("live_grep_args")
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopeUndo",
        callback = function()
          lazy_load_ext("undo")
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopeDap",
        callback = function()
          lazy_load_ext("dap")
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopeUiSelect",
        callback = function()
          lazy_load_ext("ui-select")
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopePersisted",
        callback = function()
          lazy_load_ext("persisted")
        end,
      })
    end,
    keys = function()
      local tbuiltin = require("telescope.builtin")
      local textensions = require("telescope").extensions
      return {
        {
          "<leader>ff",
          function()
            tbuiltin.find_files({ hidden = true })
          end,
          desc = "Files",
        },
        {
          "<leader>fg",
          function()
            textensions.live_grep_args.live_grep_args()
          end,
          desc = "Live grep",
        },
        {
          "<leader>fb",
          function()
            tbuiltin.buffers({
              sort_mru = true,
              ignore_current_buffer = false,
              show_all_buffers = false,
              only_cwd = false,
            })
          end,
          desc = "Buffers",
        },
        {
          "<leader>?",
          function()
            tbuiltin.commands(require("telescope.themes").get_ivy({ previewer = false }))
          end,
          desc = "Commands",
        },
        {
          "<leader>fh",
          function()
            tbuiltin.help_tags(require("telescope.themes").get_ivy())
          end,
          desc = "Help tags",
        },
        {
          "<leader>fo",
          function()
            tbuiltin.oldfiles(require("telescope.themes").get_ivy())
          end,
          desc = "Recent files",
        },
        {
          "<leader>ft",
          function()
            tbuiltin.filetypes()
          end,
          desc = "Filetypes",
        },
        {
          "<leader>fF",
          function()
            tbuiltin.builtin()
          end,
          desc = "Telescope",
        },
        {
          "<leader>fu",
          function()
            textensions.undo.undo(require("telescope.themes").get_ivy())
          end,
          desc = "Undo history",
        },
        {
          "<leader>fr",
          function()
            tbuiltin.resume()
          end,
          desc = "Resume Prior Search",
        },
      }
    end,
  },
}

return M
