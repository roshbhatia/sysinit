local M = {}

M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    opts = {
      terminals = {
        goose = {
          cmd = function()
            return string.format("GOOSE_CLI_THEME=%s goose", vim.o.background)
          end,
          path_header_template = "@%s",
        },
        codex = nil,
        claude = {
          cmd = function()
            return string.format("claude config set -g theme %s && claude", vim.o.background)
          end,
          path_header_template = "@%s",
        },
        opencode = {
          cmd = function()
            return "opencode"
          end,
          path_header_template = "@%s",
        },
        aider = nil,
      },
    },
    dependencies = { "folke/snacks.nvim" },
    keys = {
      -- Claude Keymaps
      {
        "<leader>jtc",
        function()
          require("ai-terminals").toggle("claude")
        end,
        mode = { "n", "v" },
        desc = "Toggle Claude terminal (sends selection in visual mode)",
      },
      {
        "<leader>jdc",
        function()
          require("ai-terminals").send_diagnostics("claude")
        end,
        mode = { "n", "v" },
        desc = "Send diagnostics to Claude",
      },
      -- Goose Keymaps
      {
        "<leader>jtg",
        function()
          require("ai-terminals").toggle("goose")
        end,
        mode = { "n", "v" },
        desc = "Toggle Goose terminal (sends selection in visual mode)",
      },
      {
        "<leader>jdg",
        function()
          require("ai-terminals").send_diagnostics("goose")
        end,
        mode = { "n", "v" },
        desc = "Send diagnostics to Goose",
      },
      -- OpenCode Keymaps
      {
        "<leader>jto",
        function()
          require("ai-terminals").toggle("opencode")
        end,
        mode = { "n", "v" },
        desc = "Toggle OpenCode terminal (sends selection in visual mode)",
      },
      {
        "<leader>jdo",
        function()
          require("ai-terminals").send_diagnostics("opencode")
        end,
        mode = { "n", "v" },
        desc = "Send diagnostics to OpenCode",
      },
      -- Codex Keymaps
      {
        "<leader>jtd",
        function()
          require("ai-terminals").toggle("codex")
        end,
        mode = { "n", "v" },
        desc = "Toggle Codex terminal (sends selection in visual mode)",
      },
      {
        "<leader>jdd",
        function()
          require("ai-terminals").send_diagnostics("codex")
        end,
        mode = { "n", "v" },
        desc = "Send diagnostics to Codex",
      },
      -- Generic File Management
      {
        "<leader>jf",
        function()
          require("ai-terminals").add_files_to_terminal("claude", { vim.fn.expand("%") })
        end,
        desc = "Add current file to Claude",
      },
      {
        "<leader>jF",
        function()
          require("ai-terminals").add_buffers_to_terminal("claude")
        end,
        desc = "Add all buffers to Claude",
      },
      {
        "<leader>jo",
        function()
          require("ai-terminals").add_files_to_terminal("opencode", { vim.fn.expand("%") })
        end,
        desc = "Add current file to OpenCode",
      },
      {
        "<leader>jO",
        function()
          require("ai-terminals").add_buffers_to_terminal("opencode")
        end,
        desc = "Add all buffers to OpenCode",
      },
      -- Run Command and Send Output
      {
        "<leader>jr",
        function()
          require("ai-terminals").send_command_output()
        end,
        desc = "Run command (prompts) and send output to active AI terminal",
      },
      -- Destroy All Terminals
      {
        "<leader>jx",
        function()
          require("ai-terminals").destroy_all()
        end,
        desc = "Destroy all AI terminals (closes windows, stops processes)",
      },
      -- Focus Terminal
      {
        "<leader>jz",
        function()
          require("ai-terminals").focus()
        end,
        desc = "Focus the last used AI terminal window",
      },
      -- Diff Changes
      {
        "<leader>jD",
        function()
          require("ai-terminals").diff_changes()
        end,
        desc = "Show vim diff of all changed files in tabs",
      },
    },
  },
}

return M

