-- Fix for viminfo/shada file issues
local M = {}

M.setup = function()
  -- Set shada file options to ensure compatibility
  vim.opt.shada = "'100,f1,<50,:20,/20,h"
  
  -- Pre-load patches for plugins that might have issues with shada
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  
  -- Add autocmd to prevent viminfo errors on startup
  vim.api.nvim_create_autocmd({"VimEnter"}, {
    pattern = "*",
    callback = function()
      -- Ensure clean viminfo/shada handling for Startify
      if vim.fn.exists('g:loaded_startify') == 1 then
        -- Fix the viminfo warning
        vim.g.startify_enable_special = 0
        vim.g.startify_disable_at_vimenter = 0
        vim.g.startify_update_oldfiles = 1
        
        -- Create an empty file if it doesn't exist to prevent errors
        local shada_file = vim.fn.stdpath('data') .. '/shada/main.shada'
        local f = io.open(shada_file, "r")
        if f == nil then
          -- Create the directory if it doesn't exist
          vim.fn.mkdir(vim.fn.stdpath('data') .. '/shada', 'p')
          -- Create an empty file
          f = io.open(shada_file, "w")
          if f then
            f:close()
          end
        else
          f:close()
        end
      end
    end
  })
end

return M
