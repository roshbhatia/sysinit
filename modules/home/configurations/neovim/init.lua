-- Defaults that are overriden by my nix configuration.
-- If set, just configures some installer plugins and theme configs
vim.g.nix_managed = false
vim.g.nix_transparency_enabled = false

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

require("vim._extui").enable({})

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
  spec = {
    {
      "RRethy/base16-nvim",
      lazy = false,
      config = function()
        if not vim.g.nix_managed then
          vim.cmd.colorscheme("base16-tokyo-city-terminal-light")
        end
      end,
    },
    {
      import = "sysinit.plugins",
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
  ui = {
    border = "rounded",
  },
})
