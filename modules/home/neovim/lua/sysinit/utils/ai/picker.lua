local M = {}

function M.pick_agent()
  local agents = require("sysinit.utils.ai.agents")
  local session = require("sysinit.utils.ai.session")
  local active = session.get_active()

  -- If there's an active terminal and its tmux session exists, toggle visibility
  if active and session.exists(active) then
    if session.is_visible(active) then
      session.hide(active)
    else
      session.activate(active)
    end
    return
  end

  -- Build items for Snacks picker
  local items = {}
  for _, agent in ipairs(agents.get_all()) do
    local is_active = agent.name == active
    table.insert(items, {
      text = string.format("%s %s%s", agent.icon, agent.label, is_active and " (active)" or ""),
      icon = agent.icon,
      label = agent.label,
      name = agent.name,
      agent = agent,
    })
  end

  -- Show Snacks picker with dropdown layout
  Snacks.picker.pick({
    items = items,
    layout = "vscode",
    preview = false,
    confirm = function(picker, item)
      picker:close()
      if item then
        session.activate(item.name)
      end
    end,
  })
end

function M.kill_and_pick()
  local session = require("sysinit.utils.ai.session")
  local active = session.get_active()

  if active then
    session.close(active)
  end

  M.pick_agent()
end

function M.kill_active()
  local session = require("sysinit.utils.ai.session")
  local active = session.get_active()

  if not active then
    vim.notify("No active AI session", vim.log.levels.WARN)
    return
  end

  session.close(active)
  vim.notify("AI session killed", vim.log.levels.INFO)
end

return M
