local M = {}
local history = require("sysinit.utils.ai.history")
local placeholders = require("sysinit.utils.ai.placeholders")

function M.create_input(termname, agent_icon, opts)
  opts = opts or {}
  local action_name = opts.action or "Ask"
  local prompt = string.format("%s  %s", agent_icon, action_name)
  local title = string.format("%s  %s", agent_icon or "", action_name)

  local context = require("sysinit.utils.ai.context")
  local initial_state = context.new()

  local snacks = require("snacks")
  local hist = history.load_history(termname)
  local current_history_index = history.get_current_history_index()
  history.set_current_history_index(termname, #hist + 1)

  snacks.input({
    prompt = prompt,
    title = title,
    icon = agent_icon,
    default = opts.default or "",
    win = {
      b = { completion = true },
      bo = { filetype = "ai_terminals_input" },
      wo = {
        wrap = true,
        linebreak = true,
        showbreak = "  ",
      },
      relative = "cursor",
      style = "minimal",
      border = "rounded",
      width = 80,
      height = 1,
      min_height = 1,
      max_height = 10,
      row = 1,
      col = 0,
    },
    keys = {
      i_c_j = {
        "<C-j>",
        function(snacks_input)
          if current_history_index[termname] < #hist then
            current_history_index[termname] = current_history_index[termname] + 1
            local entry = hist[current_history_index[termname]]
            if entry then
              snacks_input:set(entry.prompt)
            end
          end
        end,
        mode = "i",
        desc = "History forward",
      },
      i_c_k = {
        "<C-k>",
        function(snacks_input)
          if current_history_index[termname] > 1 then
            current_history_index[termname] = current_history_index[termname] - 1
            local entry = hist[current_history_index[termname]]
            if entry then
              snacks_input:set(entry.prompt)
            end
          elseif current_history_index[termname] == 1 then
            current_history_index[termname] = #hist + 1
            snacks_input:set("")
          end
        end,
        mode = "i",
        desc = "History backward",
      },
    },
  }, function(value)
    if opts.on_confirm and value and value ~= "" then
      history.save_to_history(termname, value)
      opts.on_confirm(placeholders.apply(value, initial_state))
    end
  end)

  -- Add placeholder syntax highlighting
  vim.schedule(function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "ai_terminals_input" then
      vim.fn.matchadd("Special", "+[%w_]\\+")
    end
  end)
end

return M
