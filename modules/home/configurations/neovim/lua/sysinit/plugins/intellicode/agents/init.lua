local M = {}

local agents = {
  require("sysinit.plugins.intellicode.agents.opencode"),
  require("sysinit.plugins.intellicode.agents.amp"),
  require("sysinit.plugins.intellicode.agents.goose"),
  require("sysinit.plugins.intellicode.agents.claude"),
  require("sysinit.plugins.intellicode.agents.cursor"),
  require("sysinit.plugins.intellicode.agents.copilot"),
}

-- Sort agents by priority (lower number = higher priority)
table.sort(agents, function(a, b)
  return (a.priority or 999) < (b.priority or 999)
end)

function M.get_all()
  return agents
end

function M.get_by_name(name)
  for _, agent in ipairs(agents) do
    if agent.name == name then
      return agent
    end
  end
  return nil
end

function M.get_by_key(key)
  for _, agent in ipairs(agents) do
    if agent.key == key then
      return agent
    end
  end
  return nil
end

return M
