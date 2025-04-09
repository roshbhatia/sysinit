-- Configure jump list navigation with leader keys
local M = {}

M.setup = function()
  -- Changed from Ctrl+b/f to leader+jb/jf for jumplist navigation
  vim.keymap.set('n', '<leader>jb', '<C-o>', { noremap = true, desc = "Go back in jump list (was Ctrl+b)" })
  vim.keymap.set('n', '<leader>jf', '<C-i>', { noremap = true, desc = "Go forward in jump list (was Ctrl+f)" })
  
  -- Additional helpful jump commands
  vim.keymap.set('n', '<leader>jl', "<cmd>lua require('telescope.builtin').jumplist()<CR>", { noremap = true, desc = "Show jump list in Telescope" })
  vim.keymap.set('n', '<leader>jj', "''", { noremap = true, desc = "Jump to previous position" })
  
  -- Create a custom command to show the jumplist in a more readable format
  vim.api.nvim_create_user_command("Jumplist", function()
    local jumplist, _ = unpack(vim.fn.getjumplist())
    local current_pos = vim.fn.getpos('.')
    
    -- Create a temporary buffer to display the jumplist
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    
    -- Format the jumplist entries
    local lines = {"Jumplist:", "========", ""}
    for i, jump in ipairs(jumplist) do
      local file = vim.fn.bufname(jump.bufnr)
      if file == "" then file = "[No Name]" end
      local line = string.format("%d: %s:%d", i, file, jump.lnum)
      table.insert(lines, line)
    end
    
    -- Set the buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Open in a split window
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'jumplist')
  end, {})

  -- Add syntax highlighting for the jumplist buffer
  vim.api.nvim_exec([[
    augroup JumplistSyntax
      autocmd!
      autocmd FileType jumplist syntax match JumplistHeader /^Jumplist:\|^========/
      autocmd FileType jumplist syntax match JumplistNumber /^\d\+/
      autocmd FileType jumplist highlight link JumplistHeader Title
      autocmd FileType jumplist highlight link JumplistNumber Number
    augroup END
  ]], false)
  
  print("Jump list navigation configured with leader keys")
end

return M
