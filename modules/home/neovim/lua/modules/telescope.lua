local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = { 
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "mrjones2014/legendary.nvim"
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
  local legendary = require("legendary")

  -- Which-key bindings
  local which_key_bindings = {
    {
      "<leader>f",
      group = "+Find",
      desc = "Telescope Fuzzy Finder"
    },
    {
      "<leader>ff",
      "<cmd>Telescope find_files<CR>",
      desc = "Find Files"
    },
    {
      "<leader>fg",
      "<cmd>Telescope live_grep<CR>",
      desc = "Live Grep"
    },
    {
      "<leader>fb",
      "<cmd>Telescope buffers<CR>",
      desc = "Find Buffers"
    },
    {
      "<leader>fh",
      "<cmd>Telescope help_tags<CR>",
      desc = "Help Tags"
    },
    {
      "<leader>fr",
      "<cmd>Telescope oldfiles<CR>",
      desc = "Recent Files"
    },
    {
      "<leader>fc",
      "<cmd>Telescope commands<CR>",
      desc = "Commands"
    },
    {
      "<leader>fk",
      "<cmd>Telescope keymaps<CR>",
      desc = "Keymaps"
    }
  }

  -- Command Palette Commands
  local command_palette_commands = {
    {
      "Telescope find_files",
      description = "Telescope: Find Files",
      category = "Telescope"
    },
    {
      "Telescope live_grep",
      description = "Telescope: Live Grep",
      category = "Telescope"
    },
    {
      "Telescope buffers",
      description = "Telescope: Buffers",
      category = "Telescope"
    },
    {
      "Telescope help_tags",
      description = "Telescope: Help Tags",
      category = "Telescope"
    },
    {
      "Telescope oldfiles",
      description = "Telescope: Recent Files",
      category = "Telescope"
    },
    {
      "Telescope commands",
      description = "Telescope: Commands",
      category = "Telescope"
    },
    {
      "Telescope keymaps",
      description = "Telescope: Keymaps",
      category = "Telescope"
    }
  }

  -- Register with Legendary
  legendary.keymaps(which_key_bindings)
  legendary.commands(command_palette_commands)

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
      desc = "Legendary Keybindings",
      command = "Which-key <leader>f",
      expected = "Should show Telescope finder group"
    },
    {
      desc = "Command Palette Commands",
      command = ":Legendary commands",
      expected = "Should show Telescope commands in Command Palette"
    }
  })
end

return M