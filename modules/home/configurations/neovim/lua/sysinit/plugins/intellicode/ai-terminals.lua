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
    },
    config = function(_, opts)
      require("ai-terminals").setup(opts)
      local sa = require("ai-terminals.snacks_actions")
      require("snacks").setup({})
      sa.apply(require("snacks").config)
    end,
  },
  keys = function()
    return {
      {
        "<leader>hh",
        function()
          require("ai-terminals").toggle("goose")
        end,
        desc = "Goose: Toggle terminal",
      },
      {
        "<leader>ha",
        function()
          require("ai-terminals").ask("goose")
        end,
        desc = "Goose: Ask",
      },
      {
        "<leader>hf",
        function()
          require("ai-terminals").fix_diagnostics("goose")
        end,
        desc = "Goose: Fix diagnostics",
      },
      {
        "<leader>hc",
        function()
          require("ai-terminals").comment("goose")
        end,
        desc = "Goose: Comment",
      },
      {
        "<leader>hl",
        function()
          require("ai-terminals").run("goose")
        end,
        desc = "Goose: Run command",
      },
      {
        "<leader>ha",
        function()
          require("ai-terminals").ask("goose")
        end,
        mode = "v",
        desc = "Goose: Ask (visual)",
      },
      {
        "<leader>hc",
        function()
          require("ai-terminals").comment("goose")
        end,
        mode = "v",
        desc = "Goose: Comment (visual)",
      },
      {
        "<leader>yy",
        function()
          require("ai-terminals").toggle("claude")
        end,
        desc = "Claude: Toggle terminal",
      },
      {
        "<leader>ya",
        function()
          require("ai-terminals").ask("claude")
        end,
        desc = "Claude: Ask",
      },
      {
        "<leader>yf",
        function()
          require("ai-terminals").fix_diagnostics("claude")
        end,
        desc = "Claude: Fix diagnostics",
      },
      {
        "<leader>yc",
        function()
          require("ai-terminals").comment("claude")
        end,
        desc = "Claude: Comment",
      },
      {
        "<leader>yl",
        function()
          require("ai-terminals").run("claude")
        end,
        desc = "Claude: Run command",
      },
      {
        "<leader>ya",
        function()
          require("ai-terminals").ask("claude")
        end,
        mode = "v",
        desc = "Claude: Ask (visual)",
      },
      {
        "<leader>yc",
        function()
          require("ai-terminals").comment("claude")
        end,
        mode = "v",
        desc = "Claude: Comment (visual)",
      },
      {
        "<leader>uu",
        function()
          require("ai-terminals").toggle("cursor")
        end,
        desc = "Cursor: Toggle terminal",
      },
      {
        "<leader>ua",
        function()
          require("ai-terminals").ask("cursor")
        end,
        desc = "Cursor: Ask",
      },
      {
        "<leader>uf",
        function()
          require("ai-terminals").fix_diagnostics("cursor")
        end,
        desc = "Cursor: Fix diagnostics",
      },
      {
        "<leader>uc",
        function()
          require("ai-terminals").comment("cursor")
        end,
        desc = "Cursor: Comment",
      },
      {
        "<leader>ul",
        function()
          require("ai-terminals").run("cursor")
        end,
        desc = "Cursor: Run command",
      },
      {
        "<leader>ua",
        function()
          require("ai-terminals").ask("cursor")
        end,
        mode = "v",
        desc = "Cursor: Ask (visual)",
      },
      {
        "<leader>uc",
        function()
          require("ai-terminals").comment("cursor")
        end,
        mode = "v",
        desc = "Cursor: Comment (visual)",
      },
    }
  end,
}

return M
