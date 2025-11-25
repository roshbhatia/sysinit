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

function M.ensure_terminal_and_send(termname, text)
  last_prompts[termname] = text

  local ai_manager = require("sysinit.plugins.intellicode.ai.ai_manager")
  local term_info = ai_manager.get_info(termname)

  if not term_info or not term_info.visible then
    ai_manager.open(termname)
    ai_manager.focus(termname)

    vim.defer_fn(function()
      ai_manager.send(termname, text, { submit = true })
    end, 300)
  else
    ai_manager.focus(termname)
    vim.defer_fn(function()
      ai_manager.send(termname, text, { submit = true })
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
