local M = {}

local agents = require("sysinit.plugins.intellicode.ai.agents")
local keymaps = require("sysinit.plugins.intellicode.ai.keymaps")
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local completion = require("sysinit.plugins.intellicode.ai.completion")

M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      completion.setup()
      require("ai-terminals").setup({
        terminals = {
          copilot = {
            cmd = "copilot --allow-all-paths --resume",
          },
          claude = {
            cmd = "claude --permission-mode plan",
          },
          cursor = {
            cmd = "cursor-agent --approve-mcps --browser",
          },
          opencode = {
            cmd = "opencode",
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
    end,
    keys = function()
      return keymaps.generate_all_keymaps(agents.get_agents())
    end,
  },
}

return M
