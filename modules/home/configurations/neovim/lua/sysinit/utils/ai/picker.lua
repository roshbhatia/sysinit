local M = {}

function M.pick_agent()
  local agents = require("sysinit.utils.ai.agents")
  local session = require("sysinit.utils.ai.session")
  local active = session.get_active()

  -- If there's an active terminal and its tmux session exists, toggle visibility
  if active and session.exists(active) then
    if session.is_visible(active) then
      -- Pane is visible -> hide it (kill WezTerm pane, keep tmux session)
      session.hide(active)
    else
      -- Pane is hidden but session exists -> bring it back
      session.activate(active)
    end
    return
  end

  -- Otherwise show picker to select an agent
  local items = {}
  for _, agent in ipairs(agents.get_all()) do
    local is_active = agent.name == active
    table.insert(items, {
      text = string.format("%s %s%s", agent.icon, agent.label, is_active and " (active)" or ""),
      agent = agent,
    })
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local themes = require("telescope.themes")

  pickers
    .new(themes.get_dropdown({}), {
      prompt_title = "Select AI Agent",
      finder = finders.new_table({
        results = items,
        entry_maker = function(item)
          return {
            value = item,
            display = item.text,
            ordinal = item.text,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            session.activate(selection.value.agent.name)
            vim.notify(
              string.format("%s %s activated", selection.value.agent.icon, selection.value.agent.label),
              vim.log.levels.INFO
            )
          end
        end)
        return true
      end,
    })
    :find()
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
