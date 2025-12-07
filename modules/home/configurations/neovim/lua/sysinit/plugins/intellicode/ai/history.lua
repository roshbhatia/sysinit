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
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope not available", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local history_data = {}

  if termname then
    local history = M.load_history(termname)
    for _, entry in ipairs(history) do
      table.insert(history_data, {
        display = string.format("[%s] %s: %s", termname, entry.timestamp, entry.prompt),
        prompt = entry.prompt,
        terminal = termname,
        timestamp = entry.timestamp,
      })
    end
  else
    local agents = { "opencode", "goose", "claude", "cursor" }
    for _, agent in ipairs(agents) do
      local history = M.load_history(agent)
      for _, entry in ipairs(history) do
        table.insert(history_data, {
          display = string.format("[%s] %s: %s", agent, entry.timestamp, entry.prompt),
          prompt = entry.prompt,
          terminal = agent,
          timestamp = entry.timestamp,
        })
      end
    end

    table.sort(history_data, function(a, b)
      return a.timestamp > b.timestamp
    end)
  end

  pickers
    .new({}, {
      prompt_title = termname and (termname .. " History") or "AI Terminals History",
      finder = finders.new_table({
        results = history_data,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            vim.fn.setreg("+", selection.value.prompt)
            vim.notify(
              "Copied to clipboard: " .. selection.value.prompt:sub(1, 50) .. "...",
              vim.log.levels.INFO
            )
          end
        end)
        return true
      end,
    })
    :find()
end

function M.get_current_history_index()
  return current_history_index
end

function M.set_current_history_index(termname, index)
  current_history_index[termname] = index
end

return M
