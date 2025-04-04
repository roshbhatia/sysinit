-- Disable compatibility with old-time vi
vim.cmd('set nocompatible')

-- Remove viminfo warning
vim.opt.viminfo:remove({'!'})

-- Set leader key before anything else
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function setup_split_keybindings()
  -- VS Code-like split keybindings
  vim.keymap.set('n', '<leader>\\', ':vsplit<CR>', {noremap = true, silent = true, desc = "Split vertically"})
  vim.keymap.set('n', '<leader>-', ':split<CR>', {noremap = true, silent = true, desc = "Split horizontally"})
  
  -- Navigate between splits (VS Code-like)
  vim.keymap.set('n', '<C-h>', '<C-w>h', {noremap = true, desc = "Move to left split"})
  vim.keymap.set('n', '<C-j>', '<C-w>j', {noremap = true, desc = "Move to split below"})
  vim.keymap.set('n', '<C-k>', '<C-w>k', {noremap = true, desc = "Move to split above"})
  vim.keymap.set('n', '<C-l>', '<C-w>l', {noremap = true, desc = "Move to right split"})
  
  -- Resize splits (VS Code-like)
  vim.keymap.set('n', '<C-Left>', ':vertical resize -2<CR>', {noremap = true, silent = true, desc = "Shrink split width"})
  vim.keymap.set('n', '<C-Right>', ':vertical resize +2<CR>', {noremap = true, silent = true, desc = "Increase split width"})
  vim.keymap.set('n', '<C-Up>', ':resize -2<CR>', {noremap = true, silent = true, desc = "Shrink split height"})
  vim.keymap.set('n', '<C-Down>', ':resize +2<CR>', {noremap = true, silent = true, desc = "Increase split height"})
end

-- VS Code-like editing keybindings
local function setup_editing_keybindings()
  -- Multi-cursor key bindings 
  vim.cmd([[
    let g:VM_maps = {}
    let g:VM_maps['Find Under'] = '<C-d>'           " start selecting down
    let g:VM_maps['Find Subword Under'] = '<C-d>'   " select exact word
    let g:VM_maps["Select All"] = '<C-S-l>'         " select all occurrences
    let g:VM_maps["Start Regex Search"] = 'g/'      " start regex search
    let g:VM_maps["Add Cursor At Pos"] = '<C-Space>' " add cursor at position
  ]])
  
  -- VS Code-like select line
  vim.keymap.set('n', '<C-a>', '0v$', {noremap = true, desc = "Select line"})
  
  -- Move lines up and down (using Leader instead of Alt to avoid conflict with Aerospace)
  vim.keymap.set('n', '<leader>j', ':m .+1<CR>==', {noremap = true, desc = "Move line down"})
  vim.keymap.set('n', '<leader>k', ':m .-2<CR>==', {noremap = true, desc = "Move line up"})
  vim.keymap.set('v', '<leader>j', ":m '>+1<CR>gv=gv", {noremap = true, desc = "Move selection down"})
  vim.keymap.set('v', '<leader>k', ":m '<-2<CR>gv=gv", {noremap = true, desc = "Move selection up"})
  
  -- Duplicate line (using Leader+Shift instead of Shift+Alt to avoid conflicts)
  vim.keymap.set('n', '<leader>J', 'yyp', {noremap = true, desc = "Duplicate line down"})
  vim.keymap.set('n', '<leader>K', 'yyP', {noremap = true, desc = "Duplicate line up"})
  
  -- Save with Ctrl+S
  vim.keymap.set('n', '<C-s>', ':w<CR>', {noremap = true, desc = "Save file"})
  vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>a', {noremap = true, desc = "Save file"})
end

-- Bootstrap initial setup
local function bootstrap_config()
  -- Set up the split and editing keybindings for VS Code-like experience
  setup_split_keybindings()
  setup_editing_keybindings()
  
  -- Create a directory for undo files if it doesn't exist
  local undodir = vim.fn.expand('~/.vim/undodir')
  if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, "p")
  end
  
  -- Load the main configuration - no fallbacks
  require('config')
end

-- Add package path to find modules in lua directory
local config_path = vim.fn.stdpath('config')
package.path = package.path .. ';' .. config_path .. '/lua/?.lua;' .. config_path .. '/lua/?/init.lua'

-- Force Startify to show on empty buffer (even if the config has issues)
vim.api.nvim_create_autocmd({"VimEnter"}, {
  pattern = "*",
  callback = function()
    -- Replace deprecated vim.lsp.buf_get_clients with vim.lsp.get_active_clients
    if vim.lsp and vim.lsp.buf_get_clients then
      vim.lsp.buf_get_clients = function(bufnr)
        return vim.lsp.get_active_clients({buffer = bufnr})
      end
    end
    
    -- Disable vertical line numbers in Startify
    vim.cmd([[
      augroup StartifyCustom
        autocmd!
        autocmd User Startified setlocal nonumber norelativenumber signcolumn=no 
        autocmd FileType startify setlocal nonumber norelativenumber signcolumn=no 
      augroup END
    ]])
    
    -- Show startify on empty buffer
    if vim.fn.argc() == 0 then
      local startify_loaded = pcall(vim.cmd, "Startify")
      if not startify_loaded then
        print("Warning: Could not load Startify on startup")
      end
    end
  end,
  group = vim.api.nvim_create_augroup("StartifyForceStart", { clear = true }),
})

-- Start the bootstrap process
bootstrap_config()