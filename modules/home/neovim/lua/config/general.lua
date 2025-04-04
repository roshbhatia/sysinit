vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- VSCode-like editor settings
-- Show matching brackets and parentheses
vim.o.showmatch = true

-- Smart case search - case insensitive unless Capital letter is used
vim.o.ignorecase = true
vim.o.smartcase = true

-- Enable mouse in all modes (VSCode-like)
vim.o.mouse = 'a'

-- Highlight search results
vim.o.hlsearch = true

-- Enable incremental search
vim.o.incsearch = true

-- Tab settings - 2 spaces to match typical VSCode defaults
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.expandtab = true
vim.o.shiftwidth = 2

-- Enable automatic indentation
vim.o.autoindent = true
vim.o.smartindent = true

-- Enable absolute line numbers (no relative numbers)
vim.wo.number = true
vim.wo.relativenumber = false

-- Improve command-line completion (similar to VSCode's command palette)
vim.o.wildmode = 'longest:full,full'
vim.o.wildmenu = true

-- Remove the annoying bell sounds
vim.o.errorbells = false
vim.o.visualbell = false

-- Use system clipboard for seamless copy/paste like VSCode
vim.o.clipboard = 'unnamedplus'

-- Enable termguicolors for full color support
vim.opt.termguicolors = true

-- Configure history and undo
vim.o.history = 1000
vim.o.undofile = true
vim.o.undodir = vim.fn.expand('~/.vim/undodir')

-- Set temporary directory for swap files
vim.o.directory = '/tmp'

-- Faster update time for better UX (like VSCode's responsiveness)
vim.o.updatetime = 100

-- Shorter timeoutlen for faster command response
vim.o.timeoutlen = 300

-- More space for displaying messages
vim.o.cmdheight = 1

-- Show sign column always (like VSCode gutter)
vim.o.signcolumn = 'yes'

-- Better splits (like VSCode's panel positioning)
vim.o.splitright = true
vim.o.splitbelow = true

-- Don't wrap lines (like VSCode default)
vim.o.wrap = false

-- Set minimum visible lines above/below cursor
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

-- Enable filetype detection and syntax highlighting
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')

-- Always show the tabline
vim.o.showtabline = 2

-- Override default fillchars for cleaner UI
vim.opt.fillchars = {eob = ' ', vert = '│', fold = '─'}

-- Set font with ligatures for GUI
vim.o.guifont = "MesloLGS NF:h12,Hack Nerd Font:h12:w-0.8:b:l"
vim.o.linespace = 2

-- Enable font ligatures if GUI supports it
if vim.fn.has("gui") == 1 or vim.g.neovide or vim.g.GuiLoaded then
    vim.o.guiligatures = "!\"#$%&()*+-./:<=>?@[]^_|~"
end

-- Set colorscheme to a textured, rich option
vim.cmd('colorscheme tokyonight')

-- Configure cursor - block in normal, line in insert (VSCode-like)
vim.o.guicursor = 'n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50'

-- Disable mode display since we have a status line
vim.o.showmode = false

-- Enable cursorline for better visual tracking
vim.o.cursorline = true

-- Better completion experience
vim.o.completeopt = 'menu,menuone,noselect'

-- VSCode-like fold settings
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
-- Don't fold by default
vim.o.foldenable = false
vim.o.foldlevel = 99

-- Hide command line when not in use (cleaner UI)
vim.o.cmdheight = 1
vim.o.laststatus = 3 -- Global statusline

-- Add visual indicator for line length
vim.wo.colorcolumn = '100'