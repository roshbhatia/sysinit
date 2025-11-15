local M = {}

M.plugins = {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "debugloop/telescope-undo.nvim",
      "Marskey/telescope-sg",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-dap.nvim",
      "nvim-telescope/telescope-fzy-native.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-tree/nvim-web-devicons",
      "nvim-treesitter/nvim-treesitter",
      "olimorris/persisted.nvim",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local themes = require("telescope.themes")

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
            },
          },
          file_ignore_patterns = {
            "%.cache",
            "%.flac",
            "%.jpeg",
            "%.jpg",
            "%.m4b",
            "%.m4v",
            "%.mp3",
            "%.o",
            "%.png",
            "%.wav",
            "**/dist/",
            ".cache",
            "Build",
            "^%.bin/",
            "^%.claude/",
            "^%.cursor/",
            "^%.direnv/",
            "^%.dist/",
            "^%.git/",
            "^%.githooks/",
            "^%.out/",
            "^%.venv/",
            "^%bin/",
            "^%development/render",
            "^%development/validate",
            "^%dist/",
            "^%models/",
            "^%node_modules/",
            "^%out/",
            "^%target/",
            "dist/",
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
          ast_grep = {
            command = {
              "ast-grep",
              "--json=stream",
            },
            grep_open_files = false,
            lang = nil,
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            no_ignore = true,
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
      
      -- Optimized extension loading with better triggers
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "gitcommit", "gitrebase" },
        callback = function()
          lazy_load_ext("persisted")
        end,
      })
      
      vim.api.nvim_create_autocmd("BufRead", {
        callback = function()
          if vim.fn.exists(":Telescope") == 2 then
            lazy_load_ext("fzy_native")
            lazy_load_ext("ui-select")
          end
        end,
        once = true,
      })
      
      -- Load debug extensions only when needed
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "dap-repl", "dapui_watches", "dapui_scopes" },
        callback = function()
          lazy_load_ext("dap")
        end,
      })
      
      -- Load undo extension only for buffers with undo
      vim.api.nvim_create_autocmd("BufRead", {
        callback = function()
          if vim.fn.undotree() ~= "" then
            lazy_load_ext("undo")
          end
        end,
      })
      
      -- Load ast-grep only for code files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "javascript", "typescript", "python", "lua", "rust", "go", "java", "cpp", "c" },
        callback = function()
          lazy_load_ext("ast_grep")
        end,
      })
      
      -- Fallback to User events for compatibility
      vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopeLiveGrep",
        callback = function()
          lazy_load_ext("live_grep_args")
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
          desc = "Find files",
        },
        {
          "<leader>fd",
          function()
            tbuiltin.diagnostics(require("telescope.themes").get_ivy())
          end,
          desc = "Find diagnostics",
        },
        {
          "<leader>fg",
          function()
            textensions.live_grep_args.live_grep_args()
          end,
          desc = "Find grep live",
        },
        {
          "<leader>fb",
          function()
            tbuiltin.buffers(require("telescope.themes").get_ivy({
              previewer = true,
              sort_mru = true,
              ignore_current_buffer = false,
              show_all_buffers = false,
              only_cwd = false,
            }))
          end,
          desc = "Find buffers",
        },
        {
          "<leader>?",
          function()
            tbuiltin.commands(require("telescope.themes").get_ivy({ previewer = false }))
          end,
          desc = "Find commands",
        },
        {
          "<leader>fh",
          function()
            tbuiltin.help_tags(require("telescope.themes").get_ivy())
          end,
          desc = "Find help tags",
        },
        {
          "<leader>ft",
          function()
            tbuiltin.filetypes()
          end,
          desc = "Find filetypes",
        },
        {
          "<leader>fF",
          function()
            tbuiltin.builtin()
          end,
          desc = "Find pickers",
        },
        {
          "<leader>fu",
          function()
            textensions.undo.undo(require("telescope.themes").get_ivy())
          end,
          desc = "Find undo history",
        },
        {
          "<leader>fr",
          function()
            tbuiltin.resume()
          end,
          desc = "Resume last search",
        },
        {
          "<leader>fs",
          function()
            vim.api.nvim_exec_autocmds("User", { pattern = "TelescopeAstGrep" })
            textensions.ast_grep.ast_grep()
          end,
          desc = "Find structural pattern (AST)",
        },
      }
    end,
  },
}

return M
