local M = {}

M.plugins = {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzy-native.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-tree/nvim-web-devicons",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local themes = require("telescope.themes")

      telescope.setup({
        defaults = {
          selection_caret = "",
          entry_prefix = "",
          results_title = false,
          prompt_title = false,
          prompt_prefix = "",
          preview_title = false,
          sorting_strategy = "ascending",
          path_display = {
            "filename_first",
          },
          wrap_results = true,
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
            i = {
              ["<Down>"] = actions.move_selection_next,
              ["<S-Tab>"] = actions.move_selection_previous,
              ["<Tab>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
            },
            n = {
              ["<CR>"] = actions.select_default,
              ["<Down>"] = actions.move_selection_next,
              ["<S-Tab>"] = actions.move_selection_previous,
              ["<S-j>"] = actions.preview_scrolling_down,
              ["<S-k>"] = actions.preview_scrolling_up,
              ["<Tab>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
              ["<localleader>s"] = actions.select_horizontal,
              ["<localleader>v"] = actions.select_vertical,
              ["j"] = actions.move_selection_next,
              ["k"] = actions.move_selection_previous,
              ["q"] = actions.close,
              ["x"] = actions.close,
            },
          },
          file_ignore_patterns = {
            "%.ai",
            "%.arw",
            "%.avi",
            "%.avif",
            "%.bmp",
            "%.cache",
            "%.cr2",
            "%.dds",
            "%.eps",
            "%.exr",
            "%.flac",
            "%.gif",
            "%.hdr",
            "%.heic",
            "%.heif",
            "%.ico",
            "%.j2k",
            "%.jp2",
            "%.jpeg",
            "%.jpg",
            "%.jpx",
            "%.jxl",
            "%.m4b",
            "%.m4v",
            "%.mkv",
            "%.mov",
            "%.mp3",
            "%.nef",
            "%.o",
            "%.pbm",
            "%.pdf",
            "%.pgm",
            "%.png",
            "%.pnm",
            "%.ppm",
            "%.psd",
            "%.raw",
            "%.svg",
            "%.tga",
            "%.tiff",
            "%.wav",
            "%.webp",
            "%.wmv",
            "%.xcf",
            "**/.next/",
            "**/.nuxt/",
            "**/build/",
            "**/dist/",
            "**/out/",
            "**/result/",
            "**/target/",
            "*.backup",
            "*.bak",
            "*.class",
            "*.dll",
            "*.dylib",
            "*.ear",
            "*.exe",
            "*.jar",
            "*.log",
            "*.pyc",
            "*.rar",
            "*.so",
            "*.swo",
            "*.swp",
            "*.tar.gz",
            "*.temp",
            "*.tmp",
            "*.war",
            "*.zip",
            "*~",
            ".DS_Store",
            ".cache",
            "Build",
            "Thumbs.db",
            "^%.bin/",
            "^%.claude/",
            "^%.cursor/",
            "^%.direnv/",
            "^%.dist/",
            "^%.git-crypt/",
            "^%.git/",
            "^%.githooks/",
            "^%.idea/",
            "^%.out/",
            "^%.serena/",
            "^%.venv/",
            "^%.vscode/",
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
          fzy_native = {
            override_generic_sorter = true,
            override_file_sorter = true,
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            no_ignore = true,
          },
        },
      })

      local exts = { "fzy_native", "ui-select" }
      for _, ext in ipairs(exts) do
        pcall(telescope.load_extension, ext)
      end
    end,
    keys = function()
      local tbuiltin = require("telescope.builtin")
      return {
        {
          "<leader>?",
          function()
            tbuiltin.commands(require("telescope.themes").get_ivy({ previewer = false }))
          end,
          desc = "Find: Commands",
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
          "<leader>fd",
          function()
            tbuiltin.diagnostics(require("telescope.themes").get_ivy())
          end,
          desc = "Find: Diagnostics",
        },
        {
          "<leader>ff",
          function()
            tbuiltin.find_files({ hidden = true })
          end,
          desc = "Find: Files",
        },
        {
          "<leader>fj",
          function()
            tbuiltin.jumplist(require("telescope.themes").get_ivy())
          end,
          desc = "Find: Jumplist",
        },
      }
    end,
  },
}

return M
