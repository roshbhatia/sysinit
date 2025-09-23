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
        backend = "snacks",
        default_position = "right",
        trigger_formatting = {
          enabled = true,
          notify = false,
        },
        watch_cwd = {
          enabled = true,
          ignore = {
            "**/.git/**",
            "**/node_modules/**",
            "**/.venv/**",
            "**/*.log",
            "**/bin/**",
            "**/dist/**",
            "**/vendor/**",
          },
          gitignore = true,
        },
        env = {
          PAGER = "bat",
        },
      })

      terminal.setup_goose_keymaps()
      terminal.setup_global_ctrl_l_keymaps()
      autocmds.setup_terminal_autocmds(agents.get_agents())
    end,
    keys = function()
      return keymaps.generate_all_keymaps(agents.get_agents())
    end,
  },
}

return M
