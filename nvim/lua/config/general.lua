vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Show matching brackets and parentheses
vim.o.showmatch = true

-- Enable case-insensitive search
vim.o.ignorecase = true

-- Enable mouse click
vim.o.mouse = 'a'

-- Highlight search results
vim.o.hlsearch = true

-- Enable incremental search
vim.o.incsearch = true

-- Set number of columns occupied by a tab
vim.o.tabstop = 4

-- Treat multiple spaces as tabstops for backspace
vim.o.softtabstop = 4

-- Convert tabs to spaces
vim.o.expandtab = true

-- Set width for automatic indents
vim.o.shiftwidth = 4

-- Enable automatic indentation
vim.o.autoindent = true

-- Show line numbers
vim.wo.number = true

-- Configure bash-like tab completions
vim.o.wildmode = 'longest,list'

-- Set an 80 column border for good coding style
vim.o.colorcolumn = '80'

-- Use system clipboard
vim.o.clipboard = 'unnamedplus'

-- Speed up scrolling in Vim
vim.o.ttyfast = true

-- Enable wildmenu for completion menu
vim.o.wildmenu = true

-- Enable termguicolors
vim.opt.termguicolors = true

-- Configure undofile settings for unlimited undo history
vim.o.undofile = true
vim.o.undodir = vim.fn.expand('~/.vim/undodir')

-- Set temporary directory for swap files
vim.o.directory = '/tmp'

-- Remove the red vertical bar
vim.o.colorcolumn = '0'

-- Enable auto-indenting based on file type
vim.cmd('filetype plugin indent on')

-- Enable syntax highlighting
vim.cmd('syntax on')

-- Always show the tabline
vim.o.showtabline = 2

-- Override default fillchars
vim.opt.fillchars = {eob = ' '}

-- Set colorscheme
vim.cmd('colorscheme flexoki-dark')
