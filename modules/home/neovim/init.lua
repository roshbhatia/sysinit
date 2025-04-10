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

-- Add the lua directory to the runtime path
vim.opt.rtp:prepend(vim.fn.expand("~/github/personal/roshbhatia/sysinit/modules/home/neovim/lua"))

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- System clipboard integration
vim.opt.clipboard = "unnamedplus"

-- Basic editor settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.showmode = false

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

-- Collect plugin specs from modules
local function collect_plugin_specs()
  local specs = {
    -- Icon support
    {
      "nvim-tree/nvim-web-devicons",
      lazy = true,
    },
    
    -- Global plugins
    {
      "mrjones2014/legendary.nvim",
      lazy = false,
      priority = 10000,
      dependencies = { 
        "folke/which-key.nvim",
        "nvim-tree/nvim-web-devicons"
      },
      config = function()
        require("legendary").setup({
          -- Legendary configuration
          keymaps = {},
          commands = {},
          autocmds = {},
          extensions = {
            which_key = {
              auto_register = true
            }
          }
        })
      end
    },
    {
      "folke/which-key.nvim",
      lazy = false,
      config = function()
        require("which-key").setup({
          win = { 
            border = "rounded",
            width = 0.8,
            height = 0.6,
          },
          icons = {
            breadcrumb = "»",
            separator = "➜",
            group = "+",
          },
          triggers = {
            { mode = "i", keys = "j" },
            { mode = "i", keys = "k" },
            { mode = "v", keys = "j" },
            { mode = "v", keys = "k" },
          }
        })
      end
    }
  }
  
  local modules = {
    "wezterm",
    "comment",
    "wilder",
    "harpoon",
    "heirline",
    "hop"
    -- Add other modules as they are created
  }
  
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
  local modules = {
    "wezterm",
    "comment",
    "wilder",
    "harpoon",
    "heirline",
    "hop"
    -- Add other modules as they are created
  }
  
  for _, module_name in ipairs(modules) do
    local ok, module = pcall(require, "modules." .. module_name)
    if ok and module.setup then
      module.setup()
    end
  end
end

-- Run module setup
setup_modules()
