-- Configure package path
do
  local config_path = vim.fn.expand('<sfile>:p:h')
  package.path = config_path .. '/lua/?.lua;' .. 
                 config_path .. '/lua/?/init.lua;' .. 
                 package.path
end

-- PHASE 3: Add core modules
-- Load core options and keymaps from modules
-- Use pcall to ensure errors don't stop execution
local options_ok, _ = pcall(require, "core.options")
if not options_ok then
  -- Fallback options if the module fails to load
  vim.opt.compatible = false
  vim.opt.number = true
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.expandtab = true
  vim.opt.smartindent = true
  vim.opt.termguicolors = true
  vim.opt.syntax = "on"
  vim.opt.backspace = "indent,eol,start"
  vim.opt.incsearch = true
  vim.opt.hlsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true
  vim.opt.mouse = "a"
  vim.opt.showcmd = true
  vim.opt.ruler = true
  vim.opt.laststatus = 2
  vim.opt.title = true
  vim.opt.cursorline = true
  vim.opt.autoread = true
  vim.opt.showmode = true
  vim.opt.hidden = true
  
  print("Using fallback options (core.options not loaded)")
end

-- Set leader key
vim.g.mapleader = " "

-- Load keymaps module
local keymaps_ok, _ = pcall(require, "core.keymaps")
if not keymaps_ok then
  -- Fallback basic keymaps if the module fails
  vim.keymap.set('n', '<leader>w', ':w<CR>', { noremap = true, silent = true })
  vim.keymap.set('n', '<leader>q', ':q<CR>', { noremap = true, silent = true })
  vim.keymap.set('n', '<leader>Q', ':qa!<CR>', { noremap = true, silent = true })
  
  print("Using fallback keymaps (core.keymaps not loaded)")
end

-- Load autocmds module (optional for now)
local autocmd_ok, _ = pcall(require, "core.autocmds")
if not autocmd_ok then
  print("Note: core.autocmds not loaded (this is normal for initial testing)")
end

-- PHASE 2: Add Lazy.nvim plugin manager with minimal plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  print("Installing lazy.nvim...")
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

-- Key mapping to show lazy ui
vim.keymap.set('n', '<leader>l', ':Lazy<CR>', { noremap = true, silent = true, desc = "Open Lazy.nvim" })

-- PHASE 4: Add selective plugins from plugins directory
require("lazy").setup({
  -- Core plugins
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      -- Simple Which-Key setup
    },
  },
  
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd[[colorscheme tokyonight]]
    end,
  },
  
  -- Import selected plugin modules
  -- Add more imports as we verify each one works
  { import = "plugins.ui" },     -- UI elements
  -- { import = "plugins.editor" }, -- Uncomment after UI plugins work
  -- { import = "plugins.tools" },  -- Uncomment later
  -- { import = "plugins.lsp" },    -- Uncomment later
  -- { import = "plugins.coding" }, -- Uncomment later
}, {
  ui = {
    -- Make sure the UI shows up
    border = "single",
    icons = {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🔑",
      plugin = "🔌",
      runtime = "💻",
      require = "🔍",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤",
    },
  },
  -- Simple configuration to minimize errors
  checker = { enabled = false },     -- Disable update checker
  change_detection = { enabled = false },  -- Disable change detection
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- Status message
vim.cmd [[
  echo "PHASE 4: Neovim with core modules and UI plugins loaded"
]]

-- Exit automatically in headless mode after config is loaded
if #vim.api.nvim_list_uis() == 0 then
  vim.cmd("qa!")
end