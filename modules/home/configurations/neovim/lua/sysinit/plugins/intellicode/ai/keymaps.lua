local M = {}
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local input = require("sysinit.plugins.intellicode.ai.input")
local history = require("sysinit.plugins.intellicode.ai.history")

local function create_mode_context_input(termname, icon, action, normal_default, visual_default)
  return function()
    local mode = vim.fn.mode()
    local default_text = mode:match("[vV]") and visual_default or normal_default
    input.create_input(termname, icon, {
      action = action,
      default = default_text,
      on_confirm = function(text)
        terminal.ensure_terminal_and_send(termname, text)
      end,
    })
  end
end

function M.create_agent_keymaps(agent)
  local ai_terminals = require("ai-terminals")
  local key_prefix, termname, label, icon = agent[1], agent[2], agent[3], agent[4]

  return {
    {
      string.format("<leader>%s%s", key_prefix, key_prefix),
      function()
        ai_terminals.toggle(termname)
      end,
      desc = string.format("%s: Toggle", label),
    },
    {
      string.format("<leader>%sv", key_prefix),
      function()
        local last_prompt = terminal.get_last_prompt(termname)
        if last_prompt and last_prompt ~= "" then
          terminal.ensure_terminal_and_send(termname, last_prompt)
        else
          vim.notify(string.format("No previous prompt found for %s", label), vim.log.levels.WARN)
        end
      end,
      desc = string.format("%s: Resend previous prompt", label),
    },
    {
      string.format("<leader>%sa", key_prefix),
      create_mode_context_input(termname, icon, "Ask", " @cursor: ", " @selection: "),
      mode = { "n", "v" },
      desc = string.format("%s: Ask", label),
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
      desc = string.format("%s: Fix diagnostics", label),
    },
    {
      string.format("<leader>%sc", key_prefix),
      create_mode_context_input(
        termname,
        icon,
        "Comment",
        " Comment @cursor: ",
        " Comment @selection: "
      ),
      mode = { "n", "v" },
      desc = string.format("%s: Comment", label),
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
      desc = string.format("%s: Send quickfix list", label),
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
      desc = string.format("%s: Send location list", label),
    },
    {
      string.format("<leader>%sr", key_prefix),
      function()
        history.create_history_picker(termname)
      end,
      desc = string.format("%s: Browse history", label),
    },
  }
end

function M.create_shared_keymaps()
  local ai_terminals = require("ai-terminals")

  return {
    {
      "<leader>ad",
      ai_terminals.diff_changes,
      desc = "AI: View diff",
    },
    {
      "<leader>ax",
      ai_terminals.revert_changes,
      desc = "AI: Revert changes",
    },
    {
      "<leader>ar",
      function()
        history.create_history_picker(nil)
      end,
      desc = "AI: Browse all history",
    },
  }
end

function M.generate_all_keymaps(agents)
  local all_keymaps = {}

  for _, agent in ipairs(agents) do
    vim.list_extend(all_keymaps, M.create_agent_keymaps(agent))
  end

  vim.list_extend(all_keymaps, M.create_shared_keymaps())

  return all_keymaps
end

return M
