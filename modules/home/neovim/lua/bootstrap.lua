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
  { import = "plugins.colorscheme" },
  { import = "plugins.which-key" },
  { import = "plugins.nvim-tree" },
  { import = "plugins.lualine" },
  { import = "plugins.telescope" },
  { import = "plugins.treesitter" },
  { import = "plugins.lsp" },
  { import = "plugins.smartsplits" }, -- Ensure smartsplits is included
  { "nvim-tree/nvim-web-devicons" },
  {
    "mrjones2014/smart-splits.nvim", -- Correct plugin name
    -- Removed Kitty-specific build step
  },
  -- Add more plugins here as needed
})

-- Automatically run Lazy sync on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    require("lazy").sync() -- Use Lua function instead of Vim command
  end,
})

print("Lazy.nvim setup complete")
