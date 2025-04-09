-- This is a standalone init file for testing with make test-neovim
-- It includes the basic configuration with error handling to ensure it loads correctly

-- Helper function to safely require modules
local function safe_require(module_name)
  local status, module = pcall(require, module_name)
  if not status then
    vim.notify('Error loading ' .. module_name .. ': ' .. tostring(module), vim.log.levels.WARN)
    return nil
  end
  return module
end

-- Basic settings
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Check if lazy.nvim is installed, and install it if not
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable", -- latest stable release
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Fix Lua package path to find modules
local config_path = vim.fn.stdpath('config')
package.path = string.format(
  "%s;%s/lua/?.lua;%s/lua/?/init.lua",
  package.path,
  config_path,
  config_path
)

-- Configure plugins with Lazy (minimal set for testing)
require("lazy").setup({
  -- UI and theming
  { "folke/tokyonight.nvim", priority = 1000 },
  { "nvim-tree/nvim-web-devicons" },
  { "nvim-tree/nvim-tree.lua" },
  
  -- Editor enhancements
  { "folke/which-key.nvim" },
  
  -- Fuzzy finding
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
})

-- Basic keymaps
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>ff', function() require('telescope.builtin').find_files() end, {})
vim.keymap.set('n', '<leader>fg', function() require('telescope.builtin').live_grep() end, {})

-- Setup basic plugins (should be safe to run)
safe_require('nvim-tree').setup{}
safe_require('which-key').setup{}

-- Set a colorscheme
pcall(function()
  vim.cmd.colorscheme("tokyonight")
end)

-- Default to a basic colorscheme if the fancy one fails
if vim.g.colors_name == nil then
  vim.cmd.colorscheme("default")
end

-- Log that the standalone config initialized successfully
vim.api.nvim_echo({{"Standalone config loaded successfully", "Normal"}}, false, {})