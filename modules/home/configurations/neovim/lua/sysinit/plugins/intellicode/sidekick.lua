local M = {}

local agents = require("sysinit.plugins.intellicode.ai.agents")
local keymaps = require("sysinit.plugins.intellicode.ai.keymaps")
local autocmds = require("sysinit.plugins.intellicode.ai.autocmds")
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local completion = require("sysinit.plugins.intellicode.ai.completion")

M.plugins = {
  {
    "folke/sidekick.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      completion.setup()

      require("sidekick").setup({
        -- Enable NES (Next Edit Suggestions) with Copilot
        nes = {
          enabled = true,
          keys = {
            -- Disable default NES keys to avoid conflicts
            apply = false,
            clear = false,
            jump = false,
            update = false,
          },
        },

        -- CLI configuration for AI tools
        cli = {
          enabled = true,
          tools = {
            copilot = {
              cmd = { "copilot", "--allow-all-paths", "--resume" },
            },
            claude = {
              cmd = { "claude", "--replay-user-messages", "-r", "--permission-mode", "plan" },
            },
            cursor = {
              cmd = { "cursor-agent", "--approve-mcps", "--browser" },
            },
            opencode = {
              cmd = { "opencode" },
            },
            goose = {
              cmd = { "goose" },
            },
          },

          -- Environment variables for all CLI tools
          env = {
            PAGER = "bat",
          },

          -- Window configuration
          win = {
            layout = "float", -- or "left", "right", "bottom", "top"
            width = 0.9,
            height = 0.9,
            title_pos = "center",
          },

          -- Multiplexer support for persistent sessions
          mux = {
            enabled = false, -- Disable for now to simplify debugging
            backend = "tmux",
            create = "terminal",
          },
        },

        -- Diff configuration
        diff = {
          inline = "words", -- "words", "chars", or false
        },
      })

      terminal.setup_goose_keymaps()
      autocmds.setup_terminal_autocmds(agents.get_agents())

      -- Register all custom keymaps
      local all_keymaps = keymaps.generate_all_keymaps(agents.get_agents())
      for _, keymap in ipairs(all_keymaps) do
        local modes = keymap.mode or "n"
        local opts = {
          desc = keymap.desc,
          silent = keymap.silent ~= false,
        }
        vim.keymap.set(modes, keymap[1], keymap[2], opts)
      end
    end,
    -- Load plugin immediately, not lazy-loaded by keys
    lazy = false,
  },
}

return M
