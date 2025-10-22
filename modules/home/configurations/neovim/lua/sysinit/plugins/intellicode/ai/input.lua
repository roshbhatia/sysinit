local M = {}
local history = require("sysinit.plugins.intellicode.ai.history")
local placeholders = require("sysinit.plugins.intellicode.ai.placeholders")
local terminal = require("sysinit.plugins.intellicode.ai.terminal")

function M.create_input(termname, agent_icon, opts)
  opts = opts or {}
  local action_name = opts.action or "Ask"
  local prompt = string.format("%s  %s", agent_icon, action_name)
  local title = string.format("%s  %s", agent_icon or "", action_name)

  local snacks = require("snacks")
  local hist = history.load_history(termname)
  history.set_current_history_index(termname, #hist + 1)

  snacks.input({
    prompt = prompt,
    title = title,
    icon = agent_icon,
    default = opts.default or "",
    win = {
      b = { completion = true },
      bo = { filetype = "ai_terminals_input" },
      relative = "cursor",
      style = "minimal",
      border = "rounded",
      width = 32,
      height = 1,
      row = 0,
      col = 1,
    },
  }, function(value)
    if opts.on_confirm and value and value ~= "" then
      history.save_to_history(termname, value)

      -- Check if value contains @astgrep - if so, handle interactively
      if placeholders.handle_interactive_astgrep(value, opts.on_confirm) then
        -- Interactive picker opened, callback will be called after selection
        return
      end

      -- No @astgrep, apply placeholders normally
      opts.on_confirm(placeholders.apply_placeholders(value))
    end
  end)

  vim.defer_fn(function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "ai_terminals_input" then
      local current_history_index = history.get_current_history_index()

      vim.keymap.set("n", "j", function()
        if current_history_index[termname] < #hist then
          current_history_index[termname] = current_history_index[termname] + 1
          local entry = hist[current_history_index[termname]]
          if entry then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(entry.prompt, "\n"))
          end
        end
      end, { buffer = buf, silent = true })

      vim.keymap.set("n", "k", function()
        if current_history_index[termname] > 1 then
          current_history_index[termname] = current_history_index[termname] - 1
          local entry = hist[current_history_index[termname]]
          if entry then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(entry.prompt, "\n"))
          end
        elseif current_history_index[termname] == 1 then
          current_history_index[termname] = #hist + 1
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
        end
      end, { buffer = buf, silent = true })
    end
  end, 100)
end

return M
