local M = {}
local config = require("sysinit.utils.config")

-- Import all the modular components
local history = require("sysinit.plugins.intellicode.ai.history")
local context = require("sysinit.plugins.intellicode.ai.context")
local git = require("sysinit.plugins.intellicode.ai.git")
local placeholders = require("sysinit.plugins.intellicode.ai.placeholders")
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local input = require("sysinit.plugins.intellicode.ai.input")
local completion = require("sysinit.plugins.intellicode.ai.completion")

-- Export placeholder descriptions for backwards compatibility
M.placeholder_descriptions = placeholders.placeholder_descriptions

-- Export blink source functions for backwards compatibility
M.new = completion.new
M.setup_blink_source = completion.setup

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

      -- Setup keymaps for goose terminals
      terminal.setup_goose_keymaps()
      
      -- Setup global CTRL+L keymaps for all AI terminals
      terminal.setup_global_ctrl_l_keymaps()
    end,
    keys = function()
      local ai_terminals = require("ai-terminals")

      local function create_keymaps(agent)
        local key_prefix, termname, label, icon = agent[1], agent[2], agent[3], agent[4]
        return {
          {
            string.format("<leader>%s%s", key_prefix, key_prefix),
            function()
              ai_terminals.toggle(termname)
            end,
            desc = "Toggle " .. label,
          },
          {
            string.format("<leader>%sv", key_prefix),
            function()
              local last_prompt = terminal.get_last_prompt(termname)
              if last_prompt and last_prompt ~= "" then
                terminal.ensure_terminal_and_send(termname, last_prompt)
              else
                vim.notify("No previous prompt found for " .. label, vim.log.levels.WARN)
              end
            end,
            desc = "Resend previous prompt to " .. label,
          },
          {
            string.format("<leader>%sa", key_prefix),
            function()
              local mode = vim.fn.mode()
              local default_text = mode:match("[vV]") and " @selection: " or " @cursor: "
              input.create_input(termname, icon, {
                action = "Ask",
                default = default_text,
                on_confirm = function(text)
                  terminal.ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            mode = { "n", "v" },
            desc = "Ask " .. label,
          },
          {
            string.format("<leader>%sf", key_prefix),
            function()
              input.create_input(termname, icon, {
                action = "Fix diagnostics",
                default = " Fix @diagnostic: ",
                on_confirm = function(text)
                  terminal.ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            desc = "Fix diagnostics with " .. label,
          },
          {
            string.format("<leader>%sc", key_prefix),
            function()
              local mode = vim.fn.mode()
              local default_text = mode:match("[vV]") and " Comment @selection: "
                or " Comment @cursor: "
              input.create_input(termname, icon, {
                action = "Comment",
                default = default_text,
                on_confirm = function(text)
                  terminal.ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            mode = { "n", "v" },
            desc = "Comment with " .. label,
          },
          {
            string.format("<leader>%sq", key_prefix),
            function()
              input.create_input(termname, icon, {
                action = "Analyze quickfix list",
                default = " Analyze @qflist: ",
                on_confirm = function(text)
                  terminal.ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            desc = "Send quickfix list to " .. label,
          },
          {
            string.format("<leader>%sl", key_prefix),
            function()
              input.create_input(termname, icon, {
                action = "Analyze location list",
                default = " Analyze @loclist: ",
                on_confirm = function(text)
                  terminal.ensure_terminal_and_send(termname, text)
                end,
              })
            end,
            desc = "Send location list to " .. label,
          },
          {
            string.format("<leader>%sd", key_prefix),
            function()
              local state = context.current_position()
              local result = git.open_diff_view(state)
              if result ~= "Diffview opened" and result ~= "Native diff view opened" then
                vim.notify(result, vim.log.levels.WARN)
              end
            end,
            desc = "View diff with " .. label,
          },
          {
            string.format("<leader>%sp", key_prefix),
            function()
              local state = context.current_position()
              local result = git.populate_qflist_with_diff(state)
              if result ~= "Quickfix list populated with diff changes" then
                vim.notify(result, vim.log.levels.WARN)
              else
                vim.notify(result, vim.log.levels.INFO)
              end
            end,
            desc = "Populate quickfix with diff for " .. label,
          },
        }
      end

      local agents = {
        {
          "h",
          "opencode",
          "OpenCode",
          "󰫼󰫰",
        },
        {
          "j",
          "goose",
          "Goose",
          "",
        },
        {
          "y",
          "claude",
          "Claude",
          "󰿟󰫮",
        },
        {
          "u",
          "cursor",
          "Cursor",
          "",
        },
      }

      local all_keymaps = vim.iter(agents):fold({}, function(acc, agent)
        return vim.list_extend(acc, create_keymaps(agent))
      end)

      for _, agent in ipairs(agents) do
        local key_prefix, termname, label = agent[1], agent[2], agent[3]
        table.insert(all_keymaps, {
          string.format("<leader>%sr", key_prefix),
          function()
            history.create_history_picker(termname)
          end,
          desc = "Browse " .. label .. " history",
        })
        table.insert(all_keymaps, {
          string.format("<leader>%sR", key_prefix),
          function()
            history.create_history_picker(nil)
          end,
          desc = "Browse all AI terminals history",
        })
      end

      vim.api.nvim_create_autocmd("TermEnter", {
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local term_name = vim.api.nvim_buf_get_name(buf)

          local current_termname = nil
          for _, agent in ipairs(agents) do
            if term_name:match(agent[2]) then
              current_termname = agent[2]
              break
            end
          end
        end,
      })

      return all_keymaps
    end,
  },
}

return M
