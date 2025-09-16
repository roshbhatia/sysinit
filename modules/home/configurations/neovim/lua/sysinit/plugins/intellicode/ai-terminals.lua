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
      prompts = {
        explain = "Explain the selected code or buffer.",
        fix_diagnostics = function()
          return "Fix the following diagnostics in this file."
        end,
        refactor = "Refactor the selected code for readability and performance.",
      },
      prompt_keymaps = {
        {
          key = "<leader>ha",
          term = "claude",
          prompt = "explain",
          desc = "Claude: Explain selection",
        },
        {
          key = "<leader>hs",
          term = "claude",
          prompt = "fix_diagnostics",
          desc = "Claude: Fix diagnostics",
          include_selection = false,
        },
        {
          key = "<leader>hd",
          term = "claude",
          prompt = "refactor",
          desc = "Claude: Refactor selection",
        },

        {
          key = "<leader>ja",
          term = "goose",
          prompt = "explain",
          desc = "Goose: Explain selection",
        },
        {
          key = "<leader>js",
          term = "goose",
          prompt = "fix_diagnostics",
          desc = "Goose: Fix diagnostics",
          include_selection = false,
        },
        {
          key = "<leader>jd",
          term = "goose",
          prompt = "refactor",
          desc = "Goose: Refactor selection",
        },

        {
          key = "<leader>ka",
          term = "cursor",
          prompt = "explain",
          desc = "Cursor: Explain selection",
        },
        {
          key = "<leader>ks",
          term = "cursor",
          prompt = "fix_diagnostics",
          desc = "Cursor: Fix diagnostics",
          include_selection = false,
        },
        {
          key = "<leader>kd",
          term = "cursor",
          prompt = "refactor",
          desc = "Cursor: Refactor selection",
        },

        {
          key = "<leader>la",
          term = "opencode",
          prompt = "explain",
          desc = "Opencode: Explain selection",
        },
        {
          key = "<leader>ls",
          term = "opencode",
          prompt = "fix_diagnostics",
          desc = "Opencode: Fix diagnostics",
          include_selection = false,
        },
        {
          key = "<leader>ld",
          term = "opencode",
          prompt = "refactor",
          desc = "Opencode: Refactor selection",
        },
      },
      auto_terminal_keymaps = {
        prefix = "<leader>h",
        terminals = {
          { name = "claude", key = "a" },
          { name = "goose", key = "j" },
          { name = "cursor", key = "k" },
          { name = "opencode", key = "l" },
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
