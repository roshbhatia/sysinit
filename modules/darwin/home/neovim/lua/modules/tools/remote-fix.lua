local M = {}

M.plugins = {}

function M.setup()
  -- Disable remote plugins if Neovim doesn't have Python support
  -- This prevents the "Invalid channel" errors on startup
  
  -- Check if Python host is available
  if vim.fn.has('python3') == 0 then
    vim.g.loaded_python3_provider = 0
    vim.g.python3_host_skip_check = 1
    
    vim.notify("Python 3 provider not available, disabled remote plugins", vim.log.levels.WARN)
  end
  
  -- Add protection against invalid remote plugin channels
  vim.api.nvim_create_autocmd("VimEnter", {
    pattern = "*",
    callback = function()
      -- Catch any startup errors with remote plugins
      local ok, err = pcall(function()
        if vim.fn.exists(':UpdateRemotePlugins') > 0 then
          vim.cmd('silent! UpdateRemotePlugins')
        end
      end)
      
      if not ok then
        vim.notify("Error with remote plugins: " .. tostring(err), vim.log.levels.WARN)
      end
    end,
  })
end

return M