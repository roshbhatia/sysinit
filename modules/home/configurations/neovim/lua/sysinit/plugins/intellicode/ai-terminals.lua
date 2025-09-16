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

      local function input_popup(opts)
        local snacks_opts = {
          prompt = opts.prompt or "Input:",
          default = opts.default or "",
          relative = "cursor",
          border = "rounded",
          title = opts.title,
          conceal = opts.conceal or false,
        }
        vim.ui.input(snacks_opts, function(value)
          if opts.on_submit then
            opts.on_submit(value)
          end
        end)
      end

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
            input_popup({
              prompt = "Send to goose:",
              on_submit = function(text)
                if text then
                  ai_terminals.send_term("goose", text, { submit = true })
                end
              end,
            })
          end,
          desc = "Goose: send",
        },
        {
          "<leader>hf",
          function()
            ai_terminals.send_diagnostics("goose", { submit = true })
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
            input_popup({
              prompt = "Run command in goose:",
              on_submit = function(cmd)
                if cmd then
                  ai_terminals.send_command_output("goose", cmd, { submit = true })
                end
              end,
            })
          end,
          desc = "Goose: Run command",
        },
        {
          "<leader>ha",
          function()
            local text = ai_terminals.get_visual_selection_with_header()
            if text then
              ai_terminals.send_term("goose", text, { submit = false })
            end
          end,
          mode = "v",
          desc = "Goose: send (visual)",
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
            input_popup({
              prompt = "Send to claude:",
              on_submit = function(text)
                if text then
                  ai_terminals.send_term("claude", text, { submit = true })
                end
              end,
            })
          end,
          desc = "Claude: send",
        },
        {
          "<leader>yf",
          function()
            ai_terminals.send_diagnostics("claude", { submit = true })
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
            input_popup({
              prompt = "Run command in claude:",
              on_submit = function(cmd)
                if cmd then
                  ai_terminals.send_command_output("claude", cmd, { submit = true })
                end
              end,
            })
          end,
          desc = "Claude: Run command",
        },
        {
          "<leader>ya",
          function()
            local text = ai_terminals.get_visual_selection_with_header()
            if text then
              ai_terminals.send_term("claude", text, { submit = false })
            end
          end,
          mode = "v",
          desc = "Claude: send (visual)",
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
            input_popup({
              prompt = "Send to cursor:",
              on_submit = function(text)
                if text then
                  ai_terminals.send_term("cursor", text, { submit = true })
                end
              end,
            })
          end,
          desc = "Cursor: send",
        },
        {
          "<leader>uf",
          function()
            ai_terminals.send_diagnostics("cursor", { submit = true })
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
            input_popup({
              prompt = "Run command in cursor:",
              on_submit = function(cmd)
                if cmd then
                  ai_terminals.send_command_output("cursor", cmd, { submit = true })
                end
              end,
            })
          end,
          desc = "Cursor: Run command",
        },
        {
          "<leader>ua",
          function()
            local text = ai_terminals.get_visual_selection_with_header()
            if text then
              ai_terminals.send_term("cursor", text, { submit = false })
            end
          end,
          mode = "v",
          desc = "Cursor: send (visual)",
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
