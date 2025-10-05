local M = {}

function M.setup_terminal_autocmds(agents)
  vim.api.nvim_create_autocmd("TermEnter", {
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local term_name = vim.api.nvim_buf_get_name(buf)

      local current_termname = nil
      for _, agent in ipairs(agents) do
        if term_name:match(agent[2]) then
          current_termname = agent[2]
          break
        end
      end

      if current_termname then
        vim.b[buf].ai_terminal_name = current_termname
      end
    end,
  })
end

return M
