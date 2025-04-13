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
    end
  }
}

function M.setup()
  local commander = require("commander")

  -- Register telescope commands with commander
  commander.add({
    {
      desc = "Find Files",
      cmd = "<cmd>Telescope find_files<CR>",
      keys = { "n", "<leader>ff" },
      cat = "Telescope"
    },
    {
      desc = "Live Grep",
      cmd = "<cmd>Telescope live_grep<CR>",
      keys = { "n", "<leader>fg" },
      cat = "Telescope"
    },
    {
      desc = "Buffers",
      cmd = "<cmd>Telescope buffers<CR>",
      keys = { "n", "<leader>fb" },
      cat = "Telescope"
    },
    {
      desc = "Help Tags",
      cmd = "<cmd>Telescope help_tags<CR>",
      keys = { "n", "<leader>fh" },
      cat = "Telescope"
    },
    {
      desc = "Recent Files",
      cmd = "<cmd>Telescope oldfiles<CR>",
      keys = { "n", "<leader>fr" },
      cat = "Telescope"
    },
    {
      desc = "Commands",
      cmd = "<cmd>Telescope commands<CR>",
      keys = { "n", "<leader>fc" },
      cat = "Telescope"
    },
    {
      desc = "Keymaps",
      cmd = "<cmd>Telescope keymaps<CR>",
      keys = { "n", "<leader>fk" },
      cat = "Telescope"
    },
    {
      desc = "Current Buffer Fuzzy Find",
      cmd = "<cmd>Telescope current_buffer_fuzzy_find<CR>",
      keys = { "n", "<leader>fs" },
      cat = "Telescope"
    }
  })
  
  -- Register verification steps
  verify.register_verification("telescope", {
    {
      desc = "Telescope Find Files",
      command = ":Telescope find_files",
      expected = "Should open Telescope file finder"
    },
    {
      desc = "Telescope Live Grep",
      command = ":Telescope live_grep",
      expected = "Should open Telescope grep search"
    },
    {
      desc = "Commander Keybindings",
      command = "<leader>ff",
      expected = "Should open Telescope finder"
    },
    {
      desc = "Commander Commands",
      command = ":Telescope commander filter cat=Telescope",
      expected = "Should show Telescope commands in Commander palette"
    }
  })
end

return M