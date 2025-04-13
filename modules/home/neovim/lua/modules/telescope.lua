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

  -- Define keymaps in legendary format
  local telescope_keymaps = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", description = "Find Files", group = "Telescope" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", description = "Live Grep", group = "Telescope" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", description = "Find Buffers", group = "Telescope" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", description = "Help Tags", group = "Telescope" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", description = "Recent Files", group = "Telescope" },
    { "<leader>fc", "<cmd>Telescope commands<CR>", description = "Commands", group = "Telescope" },
    { "<leader>fk", "<cmd>Telescope keymaps<CR>", description = "Keymaps", group = "Telescope" }
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
  legendary.keymaps(telescope_keymaps)
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