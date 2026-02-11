local M = {}

function M.pick_agent()
  local agents = require("sysinit.utils.ai.agents")
  local session = require("sysinit.utils.ai.session")
  local active = session.get_active()

  -- If there's an active terminal with a live session, toggle it
  if active and session.is_tracked(active) then
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

  if not active then
    return
  end

  session.kill_session(active)
end

function M.kill_active()
  local session = require("sysinit.utils.ai.session")
  local active = session.get_active()

  if not active then
    return
  end

  session.kill_session(active)
end

return M
