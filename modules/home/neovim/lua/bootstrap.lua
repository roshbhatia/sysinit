local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  print("Lazy.nvim installed at " .. lazypath)
end
vim.opt.rtp:prepend(lazypath)

-- Set up leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Initialize Lazy.nvim
require("lazy").setup({
  spec = {
    -- Import all plugin specifications from the plugins directory
    { import = "plugins" },
  },
  install = { colorscheme = { "carbonfox" } }, -- Set default colorscheme during installation
  checker = { enabled = true }, -- Enable automatic plugin update checks
})

-- Global variable to track Lazy.nvim UI state
vim.g.lazy_ui_state = 0

-- Bind Lazy.nvim to <leader>0
vim.keymap.set("n", "<leader>0", function()
  local lazy = require("lazy")
  if vim.g.lazy_ui_state == 0 then
    lazy.show() -- Show Lazy.nvim UI
    vim.g.lazy_ui_state = 1
  else
    vim.cmd("q") -- Close Lazy.nvim UI
    vim.g.lazy_ui_state = 0
  end
end, { noremap = true, silent = true, desc = "Toggle Lazy.nvim" })

print("Lazy.nvim setup complete")
