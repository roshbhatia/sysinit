local M = {}

local agents = require("sysinit.plugins.intellicode.agents")
local keymaps = require("sysinit.plugins.intellicode.ai.keymaps")
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local completion = require("sysinit.plugins.intellicode.ai.completion")
local file_refresh = require("sysinit.plugins.intellicode.ai.file_refresh")
local ai_manager = require("sysinit.plugins.intellicode.ai.ai_manager")

M.plugins = {
  {
    "folke/snacks.nvim",
    optional = true,
    keys = function()
      return keymaps.generate_all_keymaps()
    end,
    config = function()
      completion.setup()

      local terminals_config = {}
      for _, agent in ipairs(agents.get_all()) do
        terminals_config[agent.name] = {
          cmd = agent.cmd,
        }
      end

      ai_manager.setup({
        terminals = terminals_config,
        env = {
          PAGER = "bat",
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

      local wk_ok, wk = pcall(require, "which-key")
      if wk_ok then
        wk.add({
          { "<leader>j", group = "AI Agents" },
        })
      end
    end,
  },
}

return M
