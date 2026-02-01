local M = {}

-- Helper function to check if executable exists in PATH
local function is_executable_available(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Helper function to build full command string
local function build_command_string(agent)
  if #agent.args > 0 then
    return agent.cmd .. " " .. table.concat(agent.args, " ")
  end
  return agent.cmd
end

local agents = {
  {
    name = "opencode",
    label = "OpenCode",
    icon = "  ",
    cmd = "opencode",
    args = {},
    priority = 1,
  },
  {
    name = "claude",
    label = "Claude",
    icon = "  ",
    cmd = "claude",
    args = { "--permission-mode", "plan" },
    priority = 2,
  },
  {
    name = "goose",
    label = "Goose",
    icon = "  ",
    cmd = "goose",
    args = {},
    priority = 3,
  },
  {
    name = "amp",
    label = "Amp",
    icon = " 󰫤 ",
    cmd = "amp",
    args = { "--ide" },
    priority = 4,
  },
  {
    name = "cursor",
    label = "Cursor",
    icon = "  ",
    cmd = "cursor-agent",
    args = {},
    priority = 5,
  },
  {
    name = "copilot",
    label = "Copilot",
    icon = "  ",
    cmd = "copilot",
    args = { "--allow-all-paths" },
    priority = 6,
  },
  {
    name = "crush",
    label = "Crush",
    icon = " 󱝁 ",
    cmd = "crush",
    args = {},
    priority = 7,
  },
}

table.sort(agents, function(a, b)
  return (a.priority or 999) < (b.priority or 999)
end)

function M.get_all()
  local available_agents = {}
  for _, agent in ipairs(agents) do
    if is_executable_available(agent.cmd) then
      -- Add full command string for backward compatibility
      agent.full_cmd = build_command_string(agent)
      table.insert(available_agents, agent)
    end
  end
  return available_agents
end

function M.get_by_name(name)
  for _, agent in ipairs(agents) do
    if agent.name == name and is_executable_available(agent.cmd) then
      agent.full_cmd = build_command_string(agent)
      return agent
    end
  end
  return nil
end

function M.get_by_key(key)
  for _, agent in ipairs(agents) do
    if agent.key == key and is_executable_available(agent.cmd) then
      agent.full_cmd = build_command_string(agent)
      return agent
    end
  end
  return nil
end

return M
