-- Disable compatibility with old-time vi
vim.cmd('set nocompatible')

-- Remove viminfo warning
vim.opt.viminfo:remove({'!'})

-- Set leader key before anything else
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- VS Code-like split keybindings
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
  
  -- Move lines up and down (Alt+Up/Down in VS Code)
  vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', {noremap = true, desc = "Move line down"})
  vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', {noremap = true, desc = "Move line up"})
  vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", {noremap = true, desc = "Move selection down"})
  vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", {noremap = true, desc = "Move selection up"})
  
  -- Duplicate line (Shift+Alt+Down in VS Code)
  vim.keymap.set('n', '<S-A-j>', 'yyp', {noremap = true, desc = "Duplicate line down"})
  vim.keymap.set('n', '<S-A-k>', 'yyP', {noremap = true, desc = "Duplicate line up"})
  
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
  
  -- Try to load the main configuration
  local ok, _ = pcall(require, 'config')
  if not ok then
    vim.notify("Error loading configuration, falling back to basics", vim.log.levels.WARN)
    
    -- Setup basic keymaps if config fails to load
    vim.keymap.set('n', '<leader>ff', ':find ', {noremap = true})
    vim.keymap.set('n', '<leader>h', ':h ', {noremap = true})
    vim.keymap.set('n', '<Esc>', ':noh<CR>', {silent = true, noremap = true})
    
    -- Set basic appearance
    vim.o.number = true
    vim.o.relativenumber = true
    vim.o.cursorline = true
    vim.o.wrap = false
    vim.o.showmode = true
    vim.o.showcmd = true
    vim.o.signcolumn = 'yes'
    vim.o.termguicolors = true
    
    -- Spaces > Tabs
    vim.o.expandtab = true
    vim.o.tabstop = 2
    vim.o.shiftwidth = 2
    vim.o.smartindent = true
    
    -- Use system clipboard
    vim.o.clipboard = 'unnamedplus'
    
    -- Better undo
    vim.o.undofile = true
    vim.o.undodir = undodir
    
    -- VS Code-like cursor behavior
    vim.o.guicursor = 'n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50'
  end
end

-- Start the bootstrap process
bootstrap_config()