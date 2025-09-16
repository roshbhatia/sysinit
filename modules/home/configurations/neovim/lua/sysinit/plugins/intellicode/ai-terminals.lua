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
          right = {
            width = 0.4,
            height = 1.0,
          },
        },
        default_position = "right",
        enable_diffing = true,
        trigger_formatting = {
          enabled = true,
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
    end,
    keys = function()
      local ai_terminals = require("ai-terminals")
      local snacks = require("snacks")

      local function replace_placeholders(input)
        local buf = vim.api.nvim_get_current_buf()
        local file = vim.api.nvim_buf_get_name(buf)
        local line = vim.api.nvim_win_get_cursor(0)[1]
        local diagnostics = vim.diagnostic.get(buf, { lnum = line - 1 })

        return input
          :gsub("@cursor", string.format("%s:%d", file, line))
          :gsub("@diagnostics", function()
            if #diagnostics == 0 then
              return ""
            end
            return table.concat(
              vim.tbl_map(function(d)
                return d.message
              end, diagnostics),
              "; "
            )
          end)
      end

      local function create_input(termname, opts)
        opts = opts or {}
        local prompt = opts.prompt or "Input:"
        local snacks_opts = {
          prompt = prompt,
          title = "ask " .. termname,
          default = opts.default or "",
          on_submit = function(value)
            if opts.on_submit and value then
              opts.on_submit(replace_placeholders(value))
            end
          end,
        }
        snacks.input(snacks_opts)
      end

      local function create_keymaps(agent)
        return {
          {
            string.format("<leader>%sh", agent[1]),
            function()
              ai_terminals.toggle(agent[2])
            end,
            desc = agent[3] .. ": Toggle terminal",
          },
          {
            string.format("<leader>%sa", agent[1]),
            function()
              create_input(agent[2], {
                on_submit = function(text)
                  ai_terminals.send_term(agent[2], text, { submit = true })
                end,
              })
            end,
            desc = agent[3] .. ": Ask",
          },
          {
            string.format("<leader>%sf", agent[1]),
            function()
              ai_terminals.send_diagnostics(agent[2], { submit = true })
            end,
            desc = agent[3] .. ": Fix diagnostics",
          },
          {
            string.format("<leader>%sc", agent[1]),
            function()
              ai_terminals.comment(agent[2])
            end,
            desc = agent[3] .. ": Comment",
          },
        }
      end

      local agents = {
        { "h", "goose", "Goose" },
        { "y", "claude", "Claude" },
        { "u", "cursor", "Cursor" },
      }

      local mappings = {}
      for _, agent in ipairs(agents) do
        vim.list_extend(mappings, create_keymaps(agent))
      end

      return mappings
    end,
  },
}

return M
