local config_root = assert(vim.env.SYSINIT_NVIM_CONFIG, "SYSINIT_NVIM_CONFIG is required")
local diffview_root = assert(vim.env.SYSINIT_NVIM_DIFFVIEW, "SYSINIT_NVIM_DIFFVIEW is required")

vim.opt.runtimepath:prepend(diffview_root)
vim.opt.runtimepath:prepend(config_root)
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.cmd("runtime plugin/diffview.lua")
