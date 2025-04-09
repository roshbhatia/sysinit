local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  print("Lazy.nvim installed at " .. lazypath)
end
vim.opt.rtp:prepend(lazypath)

-- Bind Lazy.nvim to <leader>0
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>0", ":Lazy<CR>", { noremap = true, silent = true, desc = "Lazy Package Manager" })

-- Initialize Lazy.nvim
require("lazy").setup({
  -- Example plugin (add your plugins here)
  {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
  },
})

print("Lazy.nvim setup complete")
