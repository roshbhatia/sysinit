local M = {}

local session = require("sysinit.utils.ai.session")
local agents = require("sysinit.utils.ai.agents")
local input = require("sysinit.utils.ai.input")
local picker = require("sysinit.utils.ai.picker")
local history = require("sysinit.utils.ai.history")

local function ensure_active_terminal()
  local active = session.get_active()
  if not active then
    vim.notify("No active AI terminal. Select one with <leader>jj", vim.log.levels.WARN)
    return nil
  end
  return active
end

local function create_context_input(action, default_text)
  local active = ensure_active_terminal()
  if not active then
    return
  end

  local agent = agents.get_by_name(active)
  if not agent then
    return
  end

  input.create_input(active, agent.icon, {
    action = action,
    default = default_text,
    on_confirm = function(text)
      session.ensure_active_and_send(text)
    end,
  })
end

local function create_mode_context_input(action, normal_default, visual_default)
  return function()
    local mode = vim.fn.mode()
    local default_text = mode:match("[vV]") and visual_default or normal_default
    create_context_input(action, default_text)
  end
end

function M.generate_all_keymaps()
  local keymaps = {}

  table.insert(keymaps, {
    "<leader>jj",
    picker.pick_agent,
    desc = "Toggle/Pick agent",
  })

  table.insert(keymaps, {
    "<leader>jJ",
    picker.kill_and_pick,
    desc = "Kill session and pick new",
  })

  table.insert(keymaps, {
    "<leader>jx",
    picker.kill_active,
    desc = "Kill active session",
  })

  -- Direct agent activation keymaps (leader j + priority number)
  local all_agents = agents.get_all()
  for _, agent in ipairs(all_agents) do
    table.insert(keymaps, {
      "<leader>j" .. agent.priority,
      function()
        session.activate(agent.name)
        vim.notify(string.format("%s %s activated", agent.icon, agent.label), vim.log.levels.INFO)
      end,
      desc = string.format("AI: Activate %s", agent.label),
    })
  end

  table.insert(keymaps, {
    "<leader>ja",
    create_mode_context_input("Ask", " @cursor: ", " @selection: "),
    mode = { "n", "v" },
    desc = "Ask active",
  })

  table.insert(keymaps, {
    "<leader>jf",
    function()
      create_context_input("Fix diagnostics", " Fix @diagnostics: ")
    end,
    desc = "Fix diagnostics (active)",
  })

  table.insert(keymaps, {
    "<leader>jk",
    create_mode_context_input("Comment", " Comment @cursor: ", " Comment @selection: "),
    mode = { "n", "v" },
    desc = "Comment (active)",
  })

  table.insert(keymaps, {
    "<leader>jq",
    function()
      create_context_input("Analyze quickfix list", " Analyze @qflist: ")
    end,
    desc = "Send quickfix (active)",
  })

  table.insert(keymaps, {
    "<leader>jl",
    function()
      create_context_input("Analyze location list", " Analyze @loclist: ")
    end,
    desc = "Send location list (active)",
  })

  table.insert(keymaps, {
    "<leader>jv",
    function()
      local active = ensure_active_terminal()
      if not active then
        return
      end

      local terminal = require("sysinit.utils.ai.terminal")
      local last_prompt = terminal.get_last_prompt(active)
      if last_prompt and last_prompt ~= "" then
        session.ensure_active_and_send(last_prompt)
      else
        vim.notify("No previous prompt found for active terminal", vim.log.levels.WARN)
      end
    end,
    desc = "Resend previous (active)",
  })

  table.insert(keymaps, {
    "<leader>jr",
    function()
      history.create_history_picker(session.get_active())
    end,
    desc = "Browse history (active or all)",
  })

  table.insert(keymaps, {
    "<leader>jg",
    function()
      create_context_input("Review git changes", " Review @git and @diff: ")
    end,
    desc = "Review git changes (active)",
  })

  table.insert(keymaps, {
    "<leader>ji",
    function()
      create_context_input("Explain imports", " Explain @buffer: ")
    end,
    desc = "Explain imports (active)",
  })

  table.insert(keymaps, {
    "<leader>jp",
    function()
      create_context_input("Analyze clipboard", " Analyze @buffer: ")
    end,
    desc = "Analyze clipboard (active)",
  })

  return keymaps
end

return M
