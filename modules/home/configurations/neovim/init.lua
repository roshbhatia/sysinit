local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
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
  root = vim.fn.stdpath("data") .. "/lazy",
  lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json",
  rocks = {
    enabled = true,
    root = vim.fn.stdpath("data") .. "/lazy-rocks",
  },
  spec = {
    { import = "sysinit.plugins" },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "matchit",
        "matchparen",
        "shada_plugin",
      },
    },
    reset_packpath = true,
    reset_rtp = true,
  },
  change_detection = {
    notify = true,
    enabled = true,
  },
  concurrency = 12,
  dev = {
    path = vim.fn.stdpath("data") .. "/lazy-dev",
  },
  ui = {
    border = "rounded",
  },
})
