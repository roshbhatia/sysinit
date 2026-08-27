local config_root = assert(vim.env.SYSINIT_NVIM_CONFIG, "SYSINIT_NVIM_CONFIG is required")

vim.opt.runtimepath:prepend(config_root)
vim.g.mapleader = " "
vim.g.maplocalleader = ","
