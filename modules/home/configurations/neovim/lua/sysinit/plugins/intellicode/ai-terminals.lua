local M = {}

M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("ai-terminals").setup({
        terminals = {
          goose = {
            cmd = function()
              return string.format("GOOSE_CLI_THEME=%s goose", vim.o.background)
            end,
            path_header_template = "@%s",
            file_commands = {
              add_files = "@%s",
              submit = false,
            },
          },
          claude = {
            cmd = function()
              return string.format("claude config set -g theme %s && claude", vim.o.background)
            end,
            path_header_template = "@%s",
            file_commands = {
              add_files = "@%s",
              submit = false,
            },
          },
          opencode = {
            cmd = function()
              return "opencode"
            end,
            path_header_template = "@%s",
            file_commands = {
              add_files = "@%s",
              submit = false,
            },
          },
        },
        default_position = "right",
        window_dimensions = {
          float = { width = 0.8, height = 0.7 },
          bottom = { width = 1.0, height = 0.4 },
          right = { width = 0.4, height = 1.0 },
          border = "rounded",
        },
        env = {
          PAGER = "bat --style=auto --theme=auto",
          EDITOR = "nvim",
          PATH = vim.env.PATH,
        },
        enable_diffing = true,
        terminal_keymaps = {
          {
            key = "<C-w>q",
            action = "close",
            desc = "Close terminal window",
            modes = "t",
          },
          {
            key = "<Esc>",
            action = function()
              vim.cmd("stopinsert")
            end,
            desc = "Exit terminal insert mode",
            modes = "t",
          },
        },
        prompts = {
          explain_selection = "Explain the selected code snippet and its purpose.",
          review_file = "Review this file for correctness, readability, and best practices.",
          fix_diagnostics = "Fix the diagnostic issues in this code.",
          optimize_code = "Optimize this code for performance and readability.",
          add_tests = "Add comprehensive tests for this code.",
          add_docs = "Add detailed documentation comments for this code.",
        },
        prompt_keymaps = {
          {
            key = "<leader>je",
            term = "goose",
            prompt = "explain_selection",
            desc = "Explain selection with Goose",
            include_selection = true,
          },
          {
            key = "<leader>jE",
            term = "claude",
            prompt = "explain_selection",
            desc = "Explain selection with Claude",
            include_selection = true,
          },
          {
            key = "<leader>jv",
            term = "goose",
            prompt = "review_file",
            desc = "Review file with Goose",
            include_selection = false,
          },
          {
            key = "<leader>jV",
            term = "claude",
            prompt = "review_file",
            desc = "Review file with Claude",
            include_selection = false,
          },
        },
      })
    end,
    keys = function()
      return {
        -- Goose (Primary AI Terminal)
        {
          "<leader>jg",
          function()
            require("ai-terminals").toggle("goose")
          end,
          mode = { "n", "v" },
          desc = "Toggle Goose terminal",
        },
        {
          "<leader>jdg",
          function()
            require("ai-terminals").send_diagnostics("goose")
          end,
          mode = { "n", "v" },
          desc = "Send diagnostics to Goose",
        },
        {
          "<leader>jag",
          function()
            require("ai-terminals").add_files_to_terminal("goose", { vim.fn.expand("%") })
          end,
          desc = "Add current file to Goose",
        },
        {
          "<leader>jAg",
          function()
            require("ai-terminals").add_buffers_to_terminal("goose")
          end,
          desc = "Add all buffers to Goose",
        },

        -- Claude Code
        {
          "<leader>jc",
          function()
            require("ai-terminals").toggle("claude")
          end,
          mode = { "n", "v" },
          desc = "Toggle Claude terminal",
        },
        {
          "<leader>jdc",
          function()
            require("ai-terminals").send_diagnostics("claude")
          end,
          mode = { "n", "v" },
          desc = "Send diagnostics to Claude",
        },
        {
          "<leader>jac",
          function()
            require("ai-terminals").add_files_to_terminal("claude", { vim.fn.expand("%") })
          end,
          desc = "Add current file to Claude",
        },
        {
          "<leader>jAc",
          function()
            require("ai-terminals").add_buffers_to_terminal("claude")
          end,
          desc = "Add all buffers to Claude",
        },

        -- OpenCode
        {
          "<leader>jo",
          function()
            require("ai-terminals").toggle("opencode")
          end,
          mode = { "n", "v" },
          desc = "Toggle OpenCode terminal",
        },
        {
          "<leader>jdo",
          function()
            require("ai-terminals").send_diagnostics("opencode")
          end,
          mode = { "n", "v" },
          desc = "Send diagnostics to OpenCode",
        },
        {
          "<leader>jao",
          function()
            require("ai-terminals").add_files_to_terminal("opencode", { vim.fn.expand("%") })
          end,
          desc = "Add current file to OpenCode",
        },
        {
          "<leader>jAo",
          function()
            require("ai-terminals").add_buffers_to_terminal("opencode")
          end,
          desc = "Add all buffers to OpenCode",
        },

        -- Generic Actions
        {
          "<leader>jr",
          function()
            require("ai-terminals").send_command_output()
          end,
          desc = "Run command and send output",
        },
        {
          "<leader>jx",
          function()
            require("ai-terminals").destroy_all()
          end,
          desc = "Destroy all AI terminals",
        },
        {
          "<leader>jf",
          function()
            require("ai-terminals").focus()
          end,
          desc = "Focus last used terminal",
        },

        -- Diff and Change Management
        {
          "<leader>jD",
          function()
            require("ai-terminals").diff_changes()
          end,
          desc = "Show diff of AI changes",
        },
        {
          "<leader>jR",
          function()
            require("ai-terminals").revert_changes()
          end,
          desc = "Revert AI changes",
        },
        {
          "<leader>jC",
          function()
            require("ai-terminals").close_diff()
          end,
          desc = "Close diff views",
        },
      }
    end,
  },
}

return M
