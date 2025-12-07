local M = {}

-- Load agents config from nix
local config_path = vim.fn.stdpath("config") .. "/agents_config.json"
local agents_config = {}
if vim.fn.filereadable(config_path) == 1 then
  local ok, json = pcall(vim.json.decode, vim.fn.readfile(config_path))
  if ok and json then
    agents_config = json.agents or {}
  end
end

local all_agents = {
  require("sysinit.plugins.intellicode.agents.opencode"),
  require("sysinit.plugins.intellicode.agents.amp"),
  require("sysinit.plugins.intellicode.agents.goose"),
  require("sysinit.plugins.intellicode.agents.claude"),
  require("sysinit.plugins.intellicode.agents.cursor"),
  require("sysinit.plugins.intellicode.agents.copilot"),
}

-- Filter agents based on config
local agents = {}
for _, agent in ipairs(all_agents) do
  if agents_config[agent.name] ~= false then
    table.insert(agents, agent)
  end
end

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
