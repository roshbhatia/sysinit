local M = {}
local config = require("sysinit.utils.config")

M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    enabled = config.is_agents_enabled(),
    dependencies = {
      "folke/snacks.nvim",
    },
    opts = {
      terminals = {
        claude = {
          cmd = function()
            return "claude"
          end,
        },
        goose = {
          cmd = function()
            return string.format("GOOSE_CLI_THEME=%s goose", vim.o.background)
          end,
        },
        cursor = {
          cmd = function()
            return "cursor"
          end,
        },
        opencode = {
          cmd = function()
            return "opencode"
          end,
        },
      },
      window_dimensions = {
        right = { width = 0.4, height = 1.0 },
        border = "rounded",
      },
      default_position = "right",
      enable_diffing = true,
      trigger_formatting = { enabled = true },
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
      auto_terminal_keymaps = {
        prefix = "<leader>at",
        terminals = {
          { name = "opencode", key = "h" },
          { name = "goose", key = "j" },
          { name = "claude", key = "k" },
          { name = "cursor", key = "l" },
        },
      },
    },
    config = function(_, opts)
      require("ai-terminals").setup(opts)
      local sa = require("ai-terminals.snacks_actions")
      require("snacks").setup({})
      sa.apply(require("snacks").config)
    end,
  },
}

return M
