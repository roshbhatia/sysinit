-- Bootstrap lazy.nvim
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
end
vim.opt.rtp:prepend(lazypath)

-- Get the directory of the current init.lua file
local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
-- Add the lua directory relative to the init.lua location
local lua_dir = init_dir .. "/lua"
vim.opt.rtp:prepend(lua_dir)

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Explicitly register which-key trigger for leader
vim.keymap.set('n', '<Space>', '<NOP>')

-- Basic editor settings
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.showmode = true

-- Search settings
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Editing experience
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Splits and windows
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Performance options
vim.opt.updatetime = 100
vim.opt.timeoutlen = 300
vim.opt.lazyredraw = true

-- Scrolling
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false
vim.opt.foldlevel = 99

-- Other options
vim.opt.mouse = "a"
vim.opt.completeopt = { "menuone", "noselect" }

-- Define module paths
local modules = {
  "initial.commander"
  -- "initial.wezterm",
  -- "initial.wilder",
  -- "initial.heirline",
  -- "initial.carbonfox",
  -- "initial.bufferline",
  -- "initial.devicons",
  
  "main.telescope",
  -- "main.comment",
  -- "main.hop",
  -- "main.oil",
  -- "main.treesitter",
  -- "main.trouble",
}

-- Collect plugin specs from modules
local function collect_plugin_specs()
  local specs = {}
  for _, module_name in ipairs(modules) do
    local ok, module = pcall(require, "modules." .. module_name)
    if ok and module.plugins then
      vim.list_extend(specs, module.plugins)
    end
  end
  
  return specs
end

-- Setup Lazy.nvim with collected specs
require("lazy").setup(collect_plugin_specs())

-- Setup individual modules
local function setup_modules()
  for _, module_name in ipairs(modules) do
    local ok, module = pcall(require, "modules." .. module_name)
    if ok and module.setup then
      module.setup()
    end
  end
end

-- Run module setup
setup_modules()