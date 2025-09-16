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

      local snacks = require("snacks")

      local function get_cursor_context()
        local buf = vim.api.nvim_get_current_buf()
        local file = vim.api.nvim_buf_get_name(buf)
        local line = vim.api.nvim_win_get_cursor(0)[1]
        return string.format("@ cursor %s:%d", file, line)
      end

      local function get_diagnostics_context()
        local buf = vim.api.nvim_get_current_buf()
        local line = vim.api.nvim_win_get_cursor(0)[1] - 1
        local diags = vim.diagnostic.get(buf, { lnum = line })
        if #diags == 0 then
          return nil
        end
        local summary = table.concat(
          vim.tbl_map(function(d)
            return d.message
          end, diags),
          "; "
        )
        return "@ diagnostics " .. summary
      end

      local function highlight_placeholders(buf)
        local input = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
        local placeholders = { "<file>", "<range>", "<cwd>" }
        local ns_id = vim.api.nvim_create_namespace("ai_terminals_placeholders")
        vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
        for _, placeholder in ipairs(placeholders) do
          local init = 1
          while true do
            local start_pos, end_pos = input:find(placeholder, init, true)
            if not start_pos then
              break
            end
            vim.api.nvim_buf_set_extmark(buf, ns_id, 0, start_pos - 1, {
              end_col = end_pos,
              hl_group = "@lsp.type.enum",
            })
            init = end_pos + 1
          end
        end
      end

      local function ai_snacks_input(opts)
        local context = get_cursor_context()
        local diagnostics = get_diagnostics_context()
        local prompt = "󱚣 " .. context
        if diagnostics then
          prompt = prompt .. " " .. diagnostics
        end
        prompt = prompt .. "\n" .. (opts.prompt or "Input:")

        local snacks_opts = {
          prompt = prompt,
          default = opts.default or "",
          icon = "󱚣",
          icon_pos = "left",
          prompt_pos = "title",
          win = {
            style = "input",
            position = "float",
            border = "rounded",
            title_pos = "center",
            height = 1,
            width = 60,
            relative = "cursor",
            row = 0,
            wo = {
              winhighlight = "NormalFloat:SnacksInputNormal,FloatBorder:SnacksInputBorder,FloatTitle:SnacksInputTitle",
              cursorline = false,
            },
            bo = {
              filetype = "snacks_input",
              buftype = "prompt",
            },
            b = {
              completion = false,
            },
          },
          expand = true,
        }

        snacks.input(snacks_opts, function(value)
          if opts.on_submit then
            opts.on_submit(value)
          end
          -- Highlight placeholders after input
          local buf = vim.api.nvim_get_current_buf()
          highlight_placeholders(buf)
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
            ai_snacks_input({
              prompt = "",
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
            ai_snacks_input({
              prompt = "",
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
          desc = "Goose: send",
        },
        {
          "<leader>hc",
          function()
            ai_terminals.comment("goose")
          end,
          mode = "v",
          desc = "Goose: Comment",
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
            ai_snacks_input({
              prompt = "",
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
            ai_snacks_input({
              prompt = "",
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
          desc = "Claude: send",
        },
        {
          "<leader>yc",
          function()
            ai_terminals.comment("claude")
          end,
          mode = "v",
          desc = "Claude: Comment",
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
            ai_snacks_input({
              prompt = "",
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
            ai_snacks_input({
              prompt = "",
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
          desc = "Cursor: send",
        },
        {
          "<leader>uc",
          function()
            ai_terminals.comment("cursor")
          end,
          mode = "v",
          desc = "Cursor: Comment",
        },
      }
    end,
  },
}

return M
