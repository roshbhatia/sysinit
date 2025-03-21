-- Disable compatibility with old-time vi
vim.cmd('set nocompatible')

-- Remove viminfo warning
vim.opt.viminfo:remove({'!'})

require('config')
