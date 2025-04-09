-- Simple standalone init file for testing
vim.cmd [[
  set nocompatible
  syntax on
  filetype plugin indent on
  set number
  set tabstop=2
  set shiftwidth=2
  set expandtab
  set smartindent
  set termguicolors
]]

-- Simple test confirmation
print("Basic configuration loaded successfully!")