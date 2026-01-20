local M = {}

local history_dir = "/tmp"
local history_files = {}
local current_history_index = {}

function M.get_history_file(termname)
  if not history_files[termname] then
    history_files[termname] = string.format("%s/ai-terminals-history-%s.txt", history_dir, termname)
  end
  return history_files[termname]
end

function M.save_to_history(termname, prompt)
  if not prompt or prompt == "" then
    return
  end

  local history_file = M.get_history_file(termname)
  local file = io.open(history_file, "a")
  if file then
    file:write(string.format("%s|%s\n", os.date("%Y-%m-%d %H:%M:%S"), prompt))
    file:close()
  end
end

function M.load_history(termname)
  local history_file = M.get_history_file(termname)
  local history = {}
  local file = io.open(history_file, "r")
  if file then
    for line in file:lines() do
      local timestamp, prompt = line:match("^(.-)|(.*)")
      if timestamp and prompt then
        table.insert(history, { timestamp = timestamp, prompt = prompt })
      end
    end
    file:close()
  end
  return history
end

function M.create_history_picker(termname)
  local history_data = {}

  -- Load history for specific terminal or all terminals
  if termname then
    local history = M.load_history(termname)
    for _, entry in ipairs(history) do
      table.insert(history_data, {
        text = string.format("[%s] %s: %s", termname, entry.timestamp, entry.prompt),
        prompt = entry.prompt,
        terminal = termname,
        timestamp = entry.timestamp,
      })
    end
  else
    -- Load from all agents
    local agents_module = require("sysinit.utils.ai.agents")
    for _, agent in ipairs(agents_module.get_all()) do
      local history = M.load_history(agent.name)
      for _, entry in ipairs(history) do
        table.insert(history_data, {
          text = string.format("[%s] %s: %s", agent.name, entry.timestamp, entry.prompt),
          prompt = entry.prompt,
          terminal = agent.name,
          timestamp = entry.timestamp,
        })
      end
    end

    -- Sort by timestamp descending
    table.sort(history_data, function(a, b)
      return a.timestamp > b.timestamp
    end)
  end

  -- Show Snacks picker
  Snacks.picker.pick({
    prompt = termname and (termname .. " History") or "AI Terminals History",
    items = history_data,
    format = "text",
    layout = "default",
    preview = false,
    confirm = function(_, item)
      if item then
        vim.fn.setreg("+", item.prompt)
        vim.notify("Copied to clipboard: " .. item.prompt:sub(1, 50) .. "...", vim.log.levels.INFO)
      end
    end,
  })
end

function M.get_current_history_index()
  return current_history_index
end

function M.set_current_history_index(termname, index)
  current_history_index[termname] = index
end

return M
