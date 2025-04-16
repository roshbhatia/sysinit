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
        { "<leader>f", group = "Find", icon = { icon = "󰍉", hl = "WhichKeyIconPurple" } },
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files", mode = "n" },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Find Text", mode = "n" },
        { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find Buffers", mode = "n" },
        { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Find Help Tags", mode = "n" },
        { "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Find Marks", mode = "n" },
        { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Find Recent Files", mode = "n" },
        { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Find Commands", mode = "n" },
        { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Find Keymaps", mode = "n" },
        
        { "<leader>g", group = "Git", icon = { icon = "", hl = "WhichKeyIconRed" } },
        { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits", mode = "n" },
        { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches", mode = "n" },
        { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git Status", mode = "n" },
        
        { "<leader>l", group = "LSP", icon = { icon = "󰒕", hl = "WhichKeyIconBlue" } },
        { "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols", mode = "n" },
        { "<leader>lS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace Symbols", mode = "n" },
        { "<leader>lr", "<cmd>Telescope lsp_references<cr>", desc = "References", mode = "n" },
        { "<leader>li", "<cmd>Telescope lsp_implementations<cr>", desc = "Implementations", mode = "n" },
        { "<leader>ld", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Document Diagnostics", mode = "n" },
        { "<leader>lD", "<cmd>Telescope diagnostics<cr>", desc = "Workspace Diagnostics", mode = "n" },
      })
    end
  }
}

return M