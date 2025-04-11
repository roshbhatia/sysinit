local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    event = "VimEnter",
    priority = 9999,
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300  -- Lower value for faster response

      require("which-key").setup({
        plugins = {
          marks = true,
          registers = true,
          presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
          },
        },
        window = {
          border = "rounded",
          width = 0.8,
          height = 0.6,
          padding = { 2, 2, 2, 2 },
        },
        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "+",
        },
        popup_mappings = {
          scroll_down = '<c-d>',
          scroll_up = '<c-u>',
        },
        triggers = { "<leader>" },  -- Show which-key on leader key only
        triggers_nowait = {         -- These keys will trigger immediately
          "`",
          "'",
          "g",
          "[",
          "]",
        },
        triggers_blacklist = {
          -- Blacklist specific keys in insert and visual modes
          i = { "j", "k" },
          v = { "j", "k" },
        },
        disable = {
          buftypes = {},
          filetypes = { "TelescopePrompt" },
        },
      })
      
      -- Register which-key mappings using V3 format
      local wk = require("which-key")
      wk.add({
        { "<leader>", group = "Leader" },
        { "g", group = "Goto" },
        { "[", group = "Prev" },
        { "]", group = "Next" },
        { "<leader>f", group = "Find" },
        { "<leader>w", proxy = "<c-w>", group = "Window" },
        { "<leader>b", group = "Buffer", expand = function()
          return require("which-key.extras").expand.buf()
        end },
        { "<leader>c", group = "Code" },
        { "<leader>g", group = "Git" },
        
        -- Common operations
        {
          mode = { "n", "v" },
          { "<leader>q", "<cmd>q<cr>", desc = "Quit" },
          { "<leader>w", "<cmd>w<cr>", desc = "Write" },
        },

        -- File operations
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
        { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
        { "<leader>fn", "<cmd>enew<cr>", desc = "New File" },
      })
    end
  }
}

function M.setup()
  local legendary = require("legendary")

  -- Command Palette Commands
  local command_palette_commands = {
    {
      "WhichKey",
      description = "Which-key: Show help",
      category = "Which-key"
    }
  }

  -- Register with Legendary
  legendary.commands(command_palette_commands)

  -- Register verification steps
  verify.register_verification("which-key", {
    {
      desc = "Which-key Help",
      command = ":WhichKey",
      expected = "Should show which-key help menu"
    },
    {
      desc = "Leader Key Menu",
      command = "Press <leader>",
      expected = "Should show which-key leader menu"
    }
  })
end

return M