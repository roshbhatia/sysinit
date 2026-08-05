vim.loader.enable()

vim.o.sessionoptions = "blank,buffers,curdir,folds,tabpages,winsize,winpos,localoptions"

vim.o.winborder = "rounded"

vim.g.mapleader = " "
vim.g.maplocalleader = ","

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  dev = {
    path = "~/github/personal/roshbhatia",
    fallback = true,
  },
  spec = {
    {
      import = "plugins",
    },
  },
  install = {
    colorscheme = {
      "catppuccin",
    },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
