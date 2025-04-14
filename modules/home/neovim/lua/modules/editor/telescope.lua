local verify = require("core.verify")

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

      -- Set up keymaps
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', opts)
      vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', opts)
      vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>', opts)
      vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', opts)
    end
  }
}

function M.setup()
  -- Setup is now handled in the config function
end

return M