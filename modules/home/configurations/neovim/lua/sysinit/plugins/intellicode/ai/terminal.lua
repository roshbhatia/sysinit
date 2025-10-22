local M = {}

local last_prompts = {}
local placeholders = nil -- Lazy-loaded

function M.setup_goose_keymaps()
  vim.api.nvim_create_autocmd("TermEnter", {
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local term_name = vim.api.nvim_buf_get_name(buf)

      if term_name:match("goose") then
        vim.keymap.set("t", "<S-CR>", "<C-j>", {
          buffer = buf,
          silent = true,
          desc = "Send Ctrl+J in goose terminal",
        })
      end
    end,
  })
end

function M.setup_global_ctrl_l_keymaps()
  -- Ctrl+L is bound to something else, so we don't set it for AI terminals
  -- Keeping this function for backward compatibility but it does nothing now
end

function M.ensure_terminal_and_send(termname, text, opts)
  opts = opts or {}
  last_prompts[termname] = text

  local ai_terminals = require("ai-terminals")
  local term_info = ai_terminals.get_term_info and ai_terminals.get_term_info(termname)

  local function send_to_terminal()
    ai_terminals.send_term(termname, text, { submit = true })
  end

  if not term_info or not term_info.visible then
    ai_terminals.open(termname)
    ai_terminals.focus()
    vim.defer_fn(send_to_terminal, 300)
  else
    ai_terminals.focus()
    vim.defer_fn(send_to_terminal, 300)
  end
end

function M.get_last_prompt(termname)
  return last_prompts[termname]
end

function M.set_last_prompt(termname, prompt)
  last_prompts[termname] = prompt
end

return M
