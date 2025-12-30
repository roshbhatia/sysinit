local M = {}

M.plugins = {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
      "debugloop/telescope-undo.nvim",
      "Marskey/telescope-sg",
      "nvim-lua/plenary.nvim",
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
      local lga_actions = require("telescope-live-grep-args.actions")

      telescope.setup({
        defaults = {
          selection_caret = "> ",
          entry_prefix = "",
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          results_title = "Results",
          prompt_title = "",
          preview_title = "Preview",
          sorting_strategy = "ascending",
          path_display = {
            "filename_first",
            "truncate",
            "shorten",
          },
          layout_config = {
            horizontal = {
              prompt_position = "top",
              width = 0.9,
              height = 0.9,
            },
            vertical = {
              width = 0.9,
              height = 0.9,
            },
          },
          mappings = {
            n = {
              ["<CR>"] = actions.select_default,
              ["<Down>"] = actions.move_selection_next,
              ["<S-Tab>"] = actions.move_selection_previous,
              ["<Tab>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
              ["<localleader>s"] = actions.select_horizontal,
              ["<localleader>v"] = actions.select_vertical,
              ["j"] = actions.move_selection_next,
              ["k"] = actions.move_selection_previous,
              ["<S-j>"] = actions.preview_scrolling_down,
              ["<S-k>"] = actions.preview_scrolling_up,
              ["q"] = actions.close,
              ["x"] = actions.close,
            },
            i = {
              ["<Down>"] = actions.move_selection_next,
              ["<S-Tab>"] = actions.move_selection_previous,
              ["<Tab>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
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
            "^%.git-crypt/",
            "^%.githooks/",
            "^%.out/",
            "^%.serena/",
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
            themes.get_ivy(),
          },
          persisted = {
            layout_config = { width = 0.55, height = 0.55 },
          },
          fzy_native = {
            override_generic_sorter = true,
            override_file_sorter = true,
          },
          live_grep_args = {
            auto_quoting = true,
            mappings = {
              i = {
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob **/*" }),
                ["<C-space>"] = lga_actions.to_fuzzy_refine,
                ["<S-Tab>"] = actions.move_selection_previous,
                ["<Tab>"] = actions.move_selection_next,
              },
            },
            additional_args = {
              "--hidden",
              "--mmap",
              "--smart-case",
              "--threads=6",
            },
          },
          undo = {
            side_by_side = true,
            layout_strategy = "vertical",
          },
          ast_grep = {
            command = {
              "ast-grep",
              "--json=stream",
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            no_ignore = true,
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

      local exts = { "fzy_native", "ui-select", "live_grep_args", "undo", "ast_grep", "persisted" }
      for _, ext in ipairs(exts) do
        pcall(telescope.load_extension, ext)
      end
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
          desc = "Find: Files",
        },
        {
          "<leader>fo",
          function()
            tbuiltin.find_files({
              cwd = vim.fn.expand("~/org"),
              hidden = true,
              no_ignore = false,
              follow = true,
              find_command = { "fd", "--files", "--glob", "*.org", "--hidden" },
            })
          end,
          desc = "Find: Org files",
        },
        {
          "<leader>fj",
          function()
            tbuiltin.jumplist(require("telescope.themes").get_ivy())
          end,
          desc = "Find: Jumplist",
        },
        {
          "<leader>fd",
          function()
            tbuiltin.diagnostics(require("telescope.themes").get_ivy())
          end,
          desc = "Find: Diagnostics",
        },
        {
          "<leader>fg",
          function()
            textensions.live_grep_args.live_grep_args()
          end,
          desc = "Find: Grep",
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
          desc = "Find: Buffers",
        },
        {
          "<leader>?",
          function()
            tbuiltin.commands(require("telescope.themes").get_ivy({ previewer = false }))
          end,
          desc = "Find: Commands",
        },
        {
          "<leader>fh",
          function()
            tbuiltin.help_tags(require("telescope.themes").get_ivy())
          end,
          desc = "Find: Help tags",
        },
        {
          "<leader>ft",
          function()
            tbuiltin.filetypes()
          end,
          desc = "Find: Filetypes",
        },
        {
          "<leader>fF",
          function()
            tbuiltin.builtin()
          end,
          desc = "Find: Pickers",
        },
        {
          "<leader>fu",
          function()
            textensions.undo.undo(require("telescope.themes").get_ivy())
          end,
          desc = "Find: Undo history",
        },
        {
          "<leader>fr",
          function()
            tbuiltin.resume()
          end,
          desc = "Find: Resume last search",
        },
        {
          "<leader>fi",
          function()
            tbuiltin.current_buffer_fuzzy_find(
              require("telescope.themes").get_ivy({ previewer = false })
            )
          end,
          desc = "Find: In Buffer",
        },
        {
          "<leader>fs",
          function()
            vim.api.nvim_exec_autocmds("User", { pattern = "TelescopeAstGrep" })
            textensions.ast_grep.ast_grep()
          end,
          desc = "Find: Grep AST",
        },
      }
    end,
  },
}

return M
