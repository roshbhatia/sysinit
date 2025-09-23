local M = {}

local last_prompts = {}

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
  vim.api.nvim_create_autocmd("TermEnter", {
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local term_name = vim.api.nvim_buf_get_name(buf)

      -- Check if this is an AI terminal (goose, opencode, claude, cursor)
      local ai_terminals = { "goose", "opencode", "claude", "cursor" }
      local is_ai_terminal = false
      for _, term in ipairs(ai_terminals) do
        if term_name:match(term) then
          is_ai_terminal = true
          break
        end
      end

      if is_ai_terminal then
        vim.keymap.set("t", "<C-l>", "<C-l><CR>", {
          buffer = buf,
          silent = true,
          desc = "Clear screen and add newline in AI terminals",
        })
      end
    end,
  })
end

function M.ensure_terminal_and_send(termname, text)
  last_prompts[termname] = text

  local ai_terminals = require("ai-terminals")
  local term_info = ai_terminals.get_term_info and ai_terminals.get_term_info(termname)

  if not term_info or not term_info.visible then
    ai_terminals.open(termname)
    ai_terminals.focus()

    vim.defer_fn(function()
      ai_terminals.send_term(termname, text, { submit = true })
    end, 300)
  else
    ai_terminals.focus()
    vim.defer_fn(function()
      ai_terminals.send_term(termname, text, { submit = true })
    end, 300)
  end
end

function M.get_last_prompt(termname)
  return last_prompts[termname]
end

function M.set_last_prompt(termname, prompt)
  last_prompts[termname] = prompt
end

return M
