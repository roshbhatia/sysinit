local M = {}

M.agents = {
  {
    "u",
    "copilot",
    "Copilot",
    "",
  },
  {
    "j",
    "opencode",
    "OpenCode",
    "󰫼󰫰",
  },
  {
    "k",
    "goose",
    "Goose",
    "",
  },
  {
    "h",
    "claude",
    "Claude",
    "󰿟󰫮",
  },
  {
    "i",
    "cursor",
    "Cursor",
    "{}",
  },
}

function M.get_agents()
  return M.agents
end

function M.get_agent_by_termname(termname)
  for _, agent in ipairs(M.agents) do
    if agent[2] == termname then
      return agent
    end
  end
  return nil
end

function M.get_agent_by_key_prefix(key_prefix)
  for _, agent in ipairs(M.agents) do
    if agent[1] == key_prefix then
      return agent
    end
  end
  return nil
end

return M
