local M = {}

local agents = {
  {
    name = "opencode",
    label = "OpenCode",
    icon = "  ",
    cmd = "opencode",
    priority = 1,
  },
  {
    name = "claude",
    label = "Claude",
    icon = "  ",
    cmd = "claude --permission-mode plan",
    priority = 2,
  },
  {
    name = "goose",
    label = "Goose",
    icon = "  ",
    cmd = "goose",
    priority = 3,
  },
  {
    name = "amp",
    label = "Amp",
    icon = " 󰫤 ",
    cmd = "amp --ide",
    priority = 4,
  },
  {
    name = "cursor",
    label = "Cursor",
    icon = "  ",
    cmd = "cursor-agent",
    priority = 5,
  },
  {
    name = "copilot",
    label = "Copilot",
    icon = "  ",
    cmd = "copilot --allow-all-paths",
    priority = 6,
  },
  {
    name = "crush",
    label = "Crush",
    icon = " 󱝁 ",
    cmd = "crush",
    priority = 7,
  },
}

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
