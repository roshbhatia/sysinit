" Options
set autoindent
set hlsearch
set ignorecase
set incsearch
set linebreak
set number
set relativenumber
set smartcase
set smartindent

" Leader key matches neovim
let mapleader = " "

" J/K scroll 5 lines (approximates <C-d>/<C-u> feel)
noremap J 5j
noremap K 5k

" H/L to line start/end
noremap H ^
noremap L $

" Clear search highlight on Escape
nmap <Esc> :nohl

" Y yanks to end of line (matches neovim default)
nmap Y y$

" File navigation — matches <leader>ff / <leader>fg in neovim
exmap quickOpen obcommand switcher:open
nmap <leader>ff :quickOpen

exmap globalSearch obcommand global-search:open
nmap <leader>fg :globalSearch

" History navigation — matches <C-o> / <C-i> in neovim
exmap goBack obcommand app:go-back
nmap <C-o> :goBack

exmap goForward obcommand app:go-forward
nmap <C-i> :goForward

" Command palette — matches <leader><leader> in neovim
exmap commandPalette obcommand command-palette:open
nmap <leader><leader> :commandPalette

" Backlinks pane — matches <leader>e* explorer family in neovim
exmap openBacklinks obcommand backlink:open
nmap <leader>eb :openBacklinks

" Git — matches <leader>gg in neovim
exmap gitStatus obcommand obsidian-git:open-source-control-view
nmap <leader>gg :gitStatus
