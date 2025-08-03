local M = {}

function M.setup()
  -- Suppress WinResized errors entirely
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function() end,
  })

  -- Disable fold signs/gutters in floating windows
  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      local win = vim.api.nvim_get_current_win()
      local config = vim.api.nvim_win_get_config(win)
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.api.nvim_buf_get_option(buf, "filetype")

      -- Check if it's a floating window or specific filetype
      local special_filetypes = {
        "oil",
        "oil_preview",
        "avante",
        "opencode",
        "neo-tree",
        "trouble",
        "quickfix",
        "help",
        "alpha",
      }

      local should_disable = config.relative ~= "" or vim.tbl_contains(special_filetypes, ft)

      if should_disable then
        vim.wo[win].foldcolumn = "0"
        vim.wo[win].signcolumn = "no"
      end
    end,
  })

  -- Additional autocmd specifically for Oil preview windows
  vim.api.nvim_create_autocmd("User", {
    pattern = "OilEnter",
    callback = function()
      local wins = vim.api.nvim_list_wins()
      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")
        local config = vim.api.nvim_win_get_config(win)

        if ft == "oil" or config.relative ~= "" then
          vim.wo[win].foldcolumn = "0"
          vim.wo[win].signcolumn = "no"
        end
      end
    end,
  })

  -- Clear buffer list except active buffer when exiting vim
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      pcall(function()
        local current_buf = vim.api.nvim_get_current_buf()
        local buffers = vim.api.nvim_list_bufs()

        for _, buf in ipairs(buffers) do
          if buf ~= current_buf and vim.api.nvim_buf_is_loaded(buf) then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            -- Only delete buffers that are not special types
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

