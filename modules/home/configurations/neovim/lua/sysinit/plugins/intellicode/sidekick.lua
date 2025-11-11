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
            enabled = true,
            backend = "tmux", -- or "zellij"
            create = "terminal",
          },

          -- Default keymaps (we'll override most in our keymaps module)
          keys = {
            toggle = "<leader>aa",
            send_selection = "<leader>at",
            send_file = "<leader>af",
            send_visual = "<leader>av",
            pick_tool = "<leader>as",
            detach = "<leader>ad",
          },
        },

        -- Diff configuration
        diff = {
          inline = "words", -- "words", "chars", or false
        },
      })

      terminal.setup_goose_keymaps()
      autocmds.setup_terminal_autocmds(agents.get_agents())
    end,
    keys = function()
      return keymaps.generate_all_keymaps(agents.get_agents())
    end,
  },
}

return M
