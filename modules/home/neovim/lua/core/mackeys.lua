-- macOS key mappings for Neovim
-- This module provides proper command key mappings for mac users

local M = {}

M.setup = function()
  if vim.fn.has('mac') == 1 then
    -- Command+A: Select all
    vim.keymap.set('n', '<D-a>', 'ggVG', { noremap = true, silent = true, desc = "Select all text" })
    vim.keymap.set('i', '<D-a>', '<Esc>ggVG', { noremap = true, silent = true, desc = "Select all text" })
    vim.keymap.set('v', '<D-a>', '<Esc>ggVG', { noremap = true, silent = true, desc = "Select all text" })
    
    -- Command+C: Copy
    vim.keymap.set('v', '<D-c>', 'y', { noremap = true, silent = true, desc = "Copy selection" })
    vim.keymap.set('n', '<D-c>', 'yy', { noremap = true, silent = true, desc = "Copy line" })
    
    -- Command+X: Cut
    vim.keymap.set('v', '<D-x>', 'd', { noremap = true, silent = true, desc = "Cut selection" })
    vim.keymap.set('n', '<D-x>', 'dd', { noremap = true, silent = true, desc = "Cut line" })
    
    -- Command+V: Paste
    vim.keymap.set('n', '<D-v>', 'p', { noremap = true, silent = true, desc = "Paste after cursor" })
    vim.keymap.set('i', '<D-v>', '<C-r>+', { noremap = true, silent = true, desc = "Paste in insert mode" })
    vim.keymap.set('c', '<D-v>', '<C-r>+', { noremap = true, silent = true, desc = "Paste in command mode" })
    vim.keymap.set('v', '<D-v>', 'p', { noremap = true, silent = true, desc = "Paste in visual mode" })
    
    -- Set clipboard to system clipboard
    vim.opt.clipboard = "unnamedplus"
    
    print("macOS keybindings configured")
  end
end

return M
