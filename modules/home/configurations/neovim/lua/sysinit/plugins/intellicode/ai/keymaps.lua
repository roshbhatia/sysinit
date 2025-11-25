local M = {}

local ai_manager = require("sysinit.plugins.intellicode.ai.ai_manager")
local agents = require("sysinit.plugins.intellicode.agents")
local input = require("sysinit.plugins.intellicode.ai.input")
local picker = require("sysinit.plugins.intellicode.ai.picker")
local history = require("sysinit.plugins.intellicode.ai.history")

local function create_mode_context_input(action, normal_default, visual_default)
  return function()
    local active = ai_manager.get_active()
    if not active then
      vim.notify("No active AI terminal. Select one with <leader>jj", vim.log.levels.WARN)
      return
    end

    local agent = agents.get_by_name(active)
    if not agent then
      return
    end

    local mode = vim.fn.mode()
    local default_text = mode:match("[vV]") and visual_default or normal_default

    input.create_input(active, agent.icon, {
      action = action,
      default = default_text,
      on_confirm = function(text)
        ai_manager.ensure_active_and_send(text)
      end,
    })
  end
end

function M.generate_all_keymaps()
  local keymaps = {}

  table.insert(keymaps, {
    "<leader>jj",
    picker.pick_agent,
    desc = "AI: Pick agent",
  })

  for _, agent in ipairs(agents.get_all()) do
    table.insert(keymaps, {
      string.format("<leader>j%s", agent.key),
      function()
        ai_manager.activate(agent.name)
        vim.notify(string.format("%s %s activated", agent.icon, agent.label), vim.log.levels.INFO)
      end,
      desc = string.format("AI: Activate %s", agent.label),
    })
  end

  table.insert(keymaps, {
    "<leader>jt",
    function()
      local active = ai_manager.get_active()
      if not active then
        vim.notify("No active AI terminal", vim.log.levels.WARN)
        return
      end
      ai_manager.toggle(active)
    end,
    desc = "AI: Toggle active terminal",
  })

  table.insert(keymaps, {
    "<leader>ja",
    create_mode_context_input("Ask", " @cursor: ", " @selection: "),
    mode = { "n", "v" },
    desc = "AI: Ask active",
  })

  table.insert(keymaps, {
    "<leader>jf",
    function()
      local active = ai_manager.get_active()
      if not active then
        vim.notify("No active AI terminal. Select one with <leader>jj", vim.log.levels.WARN)
        return
      end

      local agent = agents.get_by_name(active)
      if not agent then
        return
      end

      input.create_input(active, agent.icon, {
        action = "Fix diagnostics",
        default = " Fix @diagnostic: ",
        on_confirm = function(text)
          ai_manager.ensure_active_and_send(text)
        end,
      })
    end,
    desc = "AI: Fix diagnostics (active)",
  })

  table.insert(keymaps, {
    "<leader>jk",
    create_mode_context_input("Comment", " Comment @cursor: ", " Comment @selection: "),
    mode = { "n", "v" },
    desc = "AI: Comment (active)",
  })

  table.insert(keymaps, {
    "<leader>jq",
    function()
      local active = ai_manager.get_active()
      if not active then
        vim.notify("No active AI terminal. Select one with <leader>jj", vim.log.levels.WARN)
        return
      end

      local agent = agents.get_by_name(active)
      if not agent then
        return
      end

      input.create_input(active, agent.icon, {
        action = "Analyze quickfix list",
        default = " Analyze @qflist: ",
        on_confirm = function(text)
          ai_manager.ensure_active_and_send(text)
        end,
      })
    end,
    desc = "AI: Send quickfix (active)",
  })

  table.insert(keymaps, {
    "<leader>jl",
    function()
      local active = ai_manager.get_active()
      if not active then
        vim.notify("No active AI terminal. Select one with <leader>jj", vim.log.levels.WARN)
        return
      end

      local agent = agents.get_by_name(active)
      if not agent then
        return
      end

      input.create_input(active, agent.icon, {
        action = "Analyze location list",
        default = " Analyze @loclist: ",
        on_confirm = function(text)
          ai_manager.ensure_active_and_send(text)
        end,
      })
    end,
    desc = "AI: Send location list (active)",
  })

  table.insert(keymaps, {
    "<leader>jv",
    function()
      local active = ai_manager.get_active()
      if not active then
        vim.notify("No active AI terminal. Select one with <leader>jj", vim.log.levels.WARN)
        return
      end

      local terminal = require("sysinit.plugins.intellicode.ai.terminal")
      local last_prompt = terminal.get_last_prompt(active)
      if last_prompt and last_prompt ~= "" then
        ai_manager.ensure_active_and_send(last_prompt)
      else
        vim.notify("No previous prompt found for active terminal", vim.log.levels.WARN)
      end
    end,
    desc = "AI: Resend previous (active)",
  })

  table.insert(keymaps, {
    "<leader>jr",
    function()
      local active = ai_manager.get_active()
      if not active then
        history.create_history_picker(nil)
      else
        history.create_history_picker(active)
      end
    end,
    desc = "AI: Browse history (active or all)",
  })

  return keymaps
end

return M
