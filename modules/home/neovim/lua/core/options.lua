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

vim.opt.backup = false                            
vim.opt.swapfile = false                         
vim.opt.undofile = true                          
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

vim.opt.foldlevel = 99                           
vim.opt.foldlevelstart = 99                      
vim.opt.foldenable = true                         

vim.opt.shortmess:append("sI")                    
vim.opt.shortmess:append("c")                     
vim.opt.whichwrap:append("<,>,[,],h,l")          

vim.opt.numberwidth = 4

vim.opt.hlsearch = true                          
vim.opt.incsearch = true                          

vim.opt.spell = false                             

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:blinkwait700-blinkoff400-blinkon250"

-- Set GUI font
if vim.fn.has("gui") == 1 or vim.g.neovide or vim.g.GuiLoaded then
  vim.opt.guifont = "Hack Nerd Font:h12:w-0.8:b:l"
  vim.opt.linespace = 2
  vim.opt.guiligatures = "!\"#$%&()*+-./:<=>?@[]^_|~"
end

vim.opt.grepprg = "rg --vimgrep --smart-case"     
vim.opt.grepformat = "%f:%l:%c:%m"                

vim.opt.tabpagemax = 30

vim.opt.redrawtime = 1500                         
vim.opt.ttyfast = true                            
-- Explicitly disable lazyredraw as it causes issues with noice.nvim
vim.opt.lazyredraw = false                        
vim.opt.synmaxcol = 200                           
vim.g.matchparen_timeout = 10                     
vim.g.matchparen_insert_timeout = 10              

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
  "matchparen",
}

for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

vim.opt.pumheight = 10

vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0