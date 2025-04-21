-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-telescope/telescope.nvim/refs/heads/master/doc/telescope.txt"
local M = {}

M.plugins = {
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = { 
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons"
    },
    config = function()
      require("telescope").setup({
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "smart" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix" }
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })
      
      local wk = require("which-key")
      wk.add({
        { "<leader>f", group = "Find", icon = { icon = "󰍉", hl = "WhichKeyIconPurple" } }, -- vscode actions: search-preview.quickOpenWithPreview, workbench.action.findInFiles, workbench.action.showAllEditors, workbench.action.showAllSymbols, workbench.action.openRecent
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files", mode = "n" },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Find Text", mode = "n" },
        { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find Buffers", mode = "n" },
        { "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Find Marks", mode = "n" },
        
        { "<leader>g", group = "Git", icon = { icon = "", hl = "WhichKeyIconRed" } }, -- vscode actions: git.stage, git.stageAll, git.unstage, git.unstageAll, git.commit, git.commitAll, git.push, git.pull, git.openChange, git.openAllChanges, git.checkout, git.fetch, git.revertChange, workbench.view.scm, workbench.action.chat.open
        { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits", mode = "n" },
        { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches", mode = "n" },
      })
    end
  }
}

return M