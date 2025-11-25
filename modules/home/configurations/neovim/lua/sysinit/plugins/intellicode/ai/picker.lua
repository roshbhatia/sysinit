local M = {}

function M.pick_agent()
  local agents = require("sysinit.plugins.intellicode.agents")
  local ai_manager = require("sysinit.plugins.intellicode.ai.ai_manager")
  local active = ai_manager.get_active()

  if active then
    if not ai_manager.is_session_valid(active) then
      ai_manager.cleanup_terminal(active)
    else
      local term_info = ai_manager.get_info(active)
      if term_info and term_info.win and vim.api.nvim_win_is_valid(term_info.win) then
        ai_manager.toggle(active)
        return
      elseif term_info then
        ai_manager.activate(active)
        return
      end
    end
  end

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

function M.kill_and_pick()
  local ai_manager = require("sysinit.plugins.intellicode.ai.ai_manager")
  local active = ai_manager.get_active()

  if active then
    ai_manager.kill_tmux_session(active)
    local term_info = ai_manager.get_info(active)
    if term_info and term_info.buf and vim.api.nvim_buf_is_valid(term_info.buf) then
      vim.api.nvim_buf_delete(term_info.buf, { force = true })
    end
  end

  M.pick_agent()
end

function M.kill_active()
  local ai_manager = require("sysinit.plugins.intellicode.ai.ai_manager")
  local active = ai_manager.get_active()

  if not active then
    vim.notify("No active AI session", vim.log.levels.WARN)
    return
  end

  ai_manager.kill_tmux_session(active)
  local term_info = ai_manager.get_info(active)
  if term_info and term_info.buf and vim.api.nvim_buf_is_valid(term_info.buf) then
    vim.api.nvim_buf_delete(term_info.buf, { force = true })
  end
  vim.notify("AI session killed", vim.log.levels.INFO)
end

return M
