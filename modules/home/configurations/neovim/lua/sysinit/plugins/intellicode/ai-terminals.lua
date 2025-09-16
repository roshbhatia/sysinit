local M = {}
local config = require("sysinit.utils.config")

M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    enabled = config.is_agents_enabled(),
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      require("ai-terminals").setup({
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
      })
    end,
    keys = function()
      local ai_terminals = require("ai-terminals")
      return {
        {
          "<leader>hh",
          function()
            ai_terminals.toggle("goose")
          end,
          desc = "Goose: Toggle terminal",
        },
        {
          "<leader>ha",
          function()
            ai_terminals.ask("goose")
          end,
          desc = "Goose: Ask",
        },
        {
          "<leader>hf",
          function()
            ai_terminals.fix_diagnostics("goose")
          end,
          desc = "Goose: Fix diagnostics",
        },
        {
          "<leader>hc",
          function()
            ai_terminals.comment("goose")
          end,
          desc = "Goose: Comment",
        },
        {
          "<leader>hl",
          function()
            ai_terminals.run("goose")
          end,
          desc = "Goose: Run command",
        },
        {
          "<leader>ha",
          function()
            ai_terminals.ask("goose")
          end,
          mode = "v",
          desc = "Goose: Ask (visual)",
        },
        {
          "<leader>hc",
          function()
            ai_terminals.comment("goose")
          end,
          mode = "v",
          desc = "Goose: Comment (visual)",
        },
        {
          "<leader>yy",
          function()
            ai_terminals.toggle("claude")
          end,
          desc = "Claude: Toggle terminal",
        },
        {
          "<leader>ya",
          function()
            ai_terminals.ask("claude")
          end,
          desc = "Claude: Ask",
        },
        {
          "<leader>yf",
          function()
            ai_terminals.fix_diagnostics("claude")
          end,
          desc = "Claude: Fix diagnostics",
        },
        {
          "<leader>yc",
          function()
            ai_terminals.comment("claude")
          end,
          desc = "Claude: Comment",
        },
        {
          "<leader>yl",
          function()
            ai_terminals.run("claude")
          end,
          desc = "Claude: Run command",
        },
        {
          "<leader>ya",
          function()
            ai_terminals.ask("claude")
          end,
          mode = "v",
          desc = "Claude: Ask (visual)",
        },
        {
          "<leader>yc",
          function()
            ai_terminals.comment("claude")
          end,
          mode = "v",
          desc = "Claude: Comment (visual)",
        },
        {
          "<leader>uu",
          function()
            ai_terminals.toggle("cursor")
          end,
          desc = "Cursor: Toggle terminal",
        },
        {
          "<leader>ua",
          function()
            ai_terminals.ask("cursor")
          end,
          desc = "Cursor: Ask",
        },
        {
          "<leader>uf",
          function()
            ai_terminals.fix_diagnostics("cursor")
          end,
          desc = "Cursor: Fix diagnostics",
        },
        {
          "<leader>uc",
          function()
            ai_terminals.comment("cursor")
          end,
          desc = "Cursor: Comment",
        },
        {
          "<leader>ul",
          function()
            ai_terminals.run("cursor")
          end,
          desc = "Cursor: Run command",
        },
        {
          "<leader>ua",
          function()
            ai_terminals.ask("cursor")
          end,
          mode = "v",
          desc = "Cursor: Ask (visual)",
        },
        {
          "<leader>uc",
          function()
            ai_terminals.comment("cursor")
          end,
          mode = "v",
          desc = "Cursor: Comment (visual)",
        },
      }
    end,
  },
}

return M
