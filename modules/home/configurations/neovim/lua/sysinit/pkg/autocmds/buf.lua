local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function() end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      local win = vim.api.nvim_get_current_win()
      local config = vim.api.nvim_win_get_config(win)
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })

      local special_filetypes = {
        "oil",
        "oil_preview",
        "opencode",
        "quickfix",
        "help",
      }

      local should_disable = config.relative ~= "" or vim.tbl_contains(special_filetypes, ft)

      if should_disable then
        vim.wo[win].foldcolumn = "0"
        vim.wo[win].signcolumn = "no"
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "OilEnter",
    callback = function()
      local wins = vim.api.nvim_list_wins()
      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
        local config = vim.api.nvim_win_get_config(win)

        if ft == "oil" or config.relative ~= "" then
          vim.wo[win].foldcolumn = "0"
          vim.wo[win].signcolumn = "no"
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      pcall(function()
        local current_buf = vim.api.nvim_get_current_buf()
        local buffers = vim.api.nvim_list_bufs()

        for _, buf in ipairs(buffers) do
          if buf ~= current_buf and vim.api.nvim_buf_is_loaded(buf) then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if vim.bo[buf].buftype == "" and buf_name ~= "" then
              pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
          end
        end
      end)
    end,
  })
end

return M
