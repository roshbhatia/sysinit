local M = {}

function M.pick_agent()
  local agents = require("sysinit.plugins.intellicode.agents")
  local ai_manager = require("sysinit.plugins.intellicode.ai.ai_manager")
  local active = ai_manager.get_active()

  local items = {}
  for _, agent in ipairs(agents.get_all()) do
    local is_active = agent.name == active
    table.insert(items, {
      text = string.format("%s %s%s", agent.icon, agent.label, is_active and " (active)" or ""),
      agent = agent,
    })
  end

  vim.ui.select(items, {
    prompt = "Select AI Agent:",
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice then
      ai_manager.activate(choice.agent.name)
      vim.notify(string.format("%s %s activated", choice.agent.icon, choice.agent.label), vim.log.levels.INFO)
    end
  end)
end

return M
