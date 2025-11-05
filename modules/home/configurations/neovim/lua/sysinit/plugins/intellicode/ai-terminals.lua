local M = {}
local config = require("sysinit.utils.config")

local agents = require("sysinit.plugins.intellicode.ai.agents")
local keymaps = require("sysinit.plugins.intellicode.ai.keymaps")
local autocmds = require("sysinit.plugins.intellicode.ai.autocmds")
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local completion = require("sysinit.plugins.intellicode.ai.completion")

M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    enabled = config.is_agents_enabled(),
    dependencies = { "folke/snacks.nvim" },
    config = function()
      completion.setup()
      require("ai-terminals").setup({
        terminals = {
          copilot = {
            cmd = "copilot",
            path_header_template = "@%s",
          },
          claude = {
            cmd = "claude",
          },
          cursor = {
            cmd = "cursor-agent --background",
          },
        },
        enable_diffing = true,
        trigger_formatting = {
          enabled = true,
        },
        env = {
          PAGER = "bat",
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
