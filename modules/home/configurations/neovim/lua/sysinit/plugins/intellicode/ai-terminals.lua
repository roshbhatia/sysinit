local M = {}

local agents = require("sysinit.plugins.intellicode.ai.agents")
local keymaps = require("sysinit.plugins.intellicode.ai.keymaps")
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local completion = require("sysinit.plugins.intellicode.ai.completion")
local file_refresh = require("sysinit.plugins.intellicode.ai.file_refresh")

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
        enable_diffing = false,
        trigger_formatting = {
          enabled = false,
        },
        env = {
          PAGER = "bat",
        },
        file_refresh = {
          enable = false,
        },
      })

      terminal.setup_goose_keymaps()
      file_refresh.setup({
        file_refresh = {
          enable = true,
          timer_interval = 1000,
          updatetime = 100,
          show_notifications = true,
        },
      })
    end,
    keys = function()
      return keymaps.generate_all_keymaps(agents.get_agents())
    end,
  },
}

return M
