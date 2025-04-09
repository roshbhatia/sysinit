vim.opt.shadafile = "NONE"    
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0 
vim.g.loaded_python_provider = 0
vim.g.python3_host_prog = vim.fn.exepath("python3")

if vim.fn.executable('python3') == 0 then
  vim.g.loaded_python3_provider = 0
end

vim.opt.mouse = "a"                              
vim.opt.clipboard = "unnamedplus"                 
vim.opt.completeopt = { "menuone", "noselect" }   
vim.opt.conceallevel = 0                          
vim.opt.fileencoding = "utf-8"                    
vim.opt.ignorecase = true                         
vim.opt.smartcase = true                          
vim.opt.smartindent = true                        
vim.opt.splitbelow = true                         
vim.opt.splitright = true                         
vim.opt.termguicolors = true                      
vim.opt.timeoutlen = 300                          
vim.opt.updatetime = 100                          
vim.opt.writebackup = false                       
vim.opt.expandtab = true                          
vim.opt.shiftwidth = 2                            
vim.opt.tabstop = 2                               
vim.opt.cursorline = true                         
vim.opt.number = true                             
vim.opt.relativenumber = true                     
vim.opt.signcolumn = "yes"                        
vim.opt.wrap = false                              
vim.opt.scrolloff = 8                             
vim.opt.sidescrolloff = 8                         
vim.opt.laststatus = 3                            
vim.opt.showmode = false                          
vim.opt.fillchars:append('eob: ')                 

-- For VSCode parity and improved experience
vim.opt.backup = false                             -- No backup files
vim.opt.swapfile = false                           -- No swap files
vim.opt.undofile = true                            -- Persistent undo
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo" -- Undo directory

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

-- Enable spell checking (disabled by default but available)
vim.opt.spell = false                              -- Disable by default

-- Disable netrw if using CHADTree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Cursor settings (blinking)
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:blinkwait700-blinkoff400-blinkon250"

-- Search settings
vim.opt.grepprg = "rg --vimgrep --smart-case"     -- Use ripgrep for grep
vim.opt.grepformat = "%f:%l:%c:%m"                -- Ripgrep output format

-- Set maximum number of tabs
vim.opt.tabpagemax = 30

-- Performance optimizations
vim.opt.redrawtime = 1500                         -- Time in milliseconds for redrawing display
vim.opt.ttyfast = true                            -- Faster terminal redrawing
vim.opt.lazyredraw = true                         -- Don't redraw while executing macros
vim.opt.synmaxcol = 200                           -- Only highlight the first N cols
vim.g.matchparen_timeout = 10                     -- Reduce matchparen timeout
vim.g.matchparen_insert_timeout = 10              -- Reduce matchparen timeout in insert

-- Treesitter folding (commented out until needed)
-- vim.opt.foldmethod = "expr"
-- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- Disable some built-in plugins we don't need for faster startup
local disabled_built_ins = {
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
  "matchit",
  "matchparen", -- Disable default matchparen in favor of a faster one
}

for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

-- Maximum number of items to show in the popup menu for completion
vim.opt.pumheight = 10

-- External tools for better performance
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0