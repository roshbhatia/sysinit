-- Core Neovim options

-- General settings
vim.opt.mouse = "a"                                -- Enable mouse support
vim.opt.clipboard = "unnamedplus"                  -- Use system clipboard
vim.opt.completeopt = { "menuone", "noselect" }    -- Completion options
vim.opt.conceallevel = 0                           -- Make `` visible in markdown files
vim.opt.fileencoding = "utf-8"                     -- File encoding
vim.opt.ignorecase = true                          -- Ignore case in search
vim.opt.smartcase = true                           -- Override ignorecase if search has uppercase
vim.opt.smartindent = true                         -- Smarter indentation
vim.opt.splitbelow = true                          -- Split below
vim.opt.splitright = true                          -- Split right
vim.opt.termguicolors = true                       -- True color support
vim.opt.timeoutlen = 300                           -- Time to wait for mapped sequence (ms)
vim.opt.updatetime = 100                           -- Faster completion
vim.opt.writebackup = false                        -- Not needed with modern editors
vim.opt.expandtab = true                           -- Convert tabs to spaces
vim.opt.shiftwidth = 2                             -- Number of spaces for indentation
vim.opt.tabstop = 2                                -- Number of spaces for tabs
vim.opt.cursorline = true                          -- Highlight current line
vim.opt.number = true                              -- Line numbers
vim.opt.relativenumber = true                      -- Relative line numbers
vim.opt.signcolumn = "yes"                         -- Always show sign column
vim.opt.wrap = false                               -- Don't wrap lines
vim.opt.scrolloff = 8                              -- Minimum lines to keep above/below cursor
vim.opt.sidescrolloff = 8                          -- Minimum columns to keep left/right of cursor
vim.opt.laststatus = 3                             -- Global statusline
vim.opt.showmode = false                           -- Don't show mode as we'll use statusline
vim.opt.fillchars:append('eob: ')                  -- Hide ~ at end of buffer

-- For VSCode parity
vim.opt.backup = false                             -- No backup files
vim.opt.swapfile = false                           -- No swap files
vim.opt.undofile = true                            -- Persistent undo

-- Folding (prepare for nvim-ufo)
vim.opt.foldlevel = 99                             -- Start with all folds open
vim.opt.foldlevelstart = 99                        -- Start with all folds open
vim.opt.foldenable = true                          -- Enable folding

-- Startup settings
vim.opt.shortmess:append("sI")                     -- Disable intro message
vim.opt.shortmess:append("c")                      -- Don't show completion messages
vim.opt.whichwrap:append("<,>,[,],h,l")            -- Keys that can wrap to next/prev line

-- Line numbering visibility
vim.opt.numberwidth = 4

-- Make search visually pleasing
vim.opt.hlsearch = true                            -- Highlight search results
vim.opt.incsearch = true                           -- Incremental search

-- Remove the <> from concealed characters
vim.opt.conceallevel = 2
vim.opt.concealcursor = 'nc'

-- Enable spell checking
vim.opt.spell = false                              -- Disable by default but enable in specific files

-- Recommended for nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Cursor settings (blinking)
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:blinkwait700-blinkoff400-blinkon250"

-- Search settings
vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"

-- Set maximum number of tabs
vim.opt.tabpagemax = 30