vim.g.vscode = (vim.fn.exists('g:vscode') == 1) or (vim.env.VSCODE_GIT_IPC_HANDLE ~= nil)

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

local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
local lua_dir = init_dir .. "/lua"
vim.opt.rtp:prepend(lua_dir)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.clipboard = "unnamedplus"

vim.keymap.set('n', ':', ':', { noremap = true, desc = "Command mode" })

-- Common settings
local function setup_common_settings()
  vim.opt.hlsearch = true
  vim.opt.incsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.smartindent = true
  vim.opt.wrap = false
  vim.opt.linebreak = true
  vim.opt.breakindent = true

  vim.opt.splitbelow = true
  vim.opt.splitright = true

  vim.opt.updatetime = 100
  vim.opt.timeoutlen = 300

  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8

  vim.opt.mouse = "a"
  vim.opt.clipboard = "unnamedplus"
end

local function setup_neovim_settings()
  vim.opt.number = true
  vim.opt.cursorline = true
  vim.opt.signcolumn = "yes"
  vim.opt.termguicolors = true
  vim.opt.showmode = false  -- Hide mode since we use lualine
  vim.opt.lazyredraw = true
  
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  vim.opt.foldenable = false
  vim.opt.foldlevel = 99

  vim.opt.pumheight = 10        -- Limit completion menu height
  vim.opt.cmdheight = 1         -- More space for displaying messages
  vim.opt.hidden = true         -- Enable background buffers
  vim.opt.showtabline = 2       -- Always show tabline
  vim.opt.shortmess:append("c") -- Don't show completion messages
  vim.opt.completeopt = { "menuone", "noselect" }
end

local function setup_vscode_settings()
  vim.notify("SysInit -- VSCode Neovim integration detected", vim.log.levels.INFO)
end

setup_common_settings()
if vim.g.vscode then
  setup_vscode_settings()
else
  setup_neovim_settings()
end

local module_loader = require("core.module_loader")

local module_system

if not vim.g.vscode then
  module_system = {
    -- UI-related modules (load first)
    ui = {
      "devicons",
      "nvimtree",
      "dropbar",
      "lualine",
      "neominimap",
      "wezterm",
      "barbar",
      "alpha",
      "themify",
    },
    -- Core editor functionality
    editor = {
      "which-key",
      "telescope",
      "oil",
      "wilder",
    },
    -- Tool modules
    tools = {
      "autosession",
      "comment",
      "hop",
      "neoscroll",
      "treesitter",
      "cmp",
      "conform",
      "lsp-zero",
      "nvim-lint",
      "copilot",
      "copilot-chat",
      "copilot-cmp",
      "autopairs",
    }
  }
else
  -- VSCode-Neovim modules (minimal set)
  module_system = {
    -- Core functionality
    editor = {
      "which-key",
      "vscode",
    },
    -- No UI modules needed
    ui = {},
    -- Minimal tool modules
    tools = {
      "autosession",
      "comment",
      "hop",
      "neoscroll",
    }
  }
end

local function collect_plugin_specs()
  local specs = module_loader.get_plugin_specs(module_system)
  
  if not vim.g.vscode then
    table.insert(specs, {
      "lewis6991/gitsigns.nvim",
      config = function()
        require("gitsigns").setup()
      end
    })
  end
  
  return specs
end

require("lazy").setup(collect_plugin_specs())

module_loader.setup_modules(module_system)

if vim.g.vscode then
  local vscode_module = require("modules.editor.vscode")
  if vscode_module and vscode_module.setup_compat_plugins then
    vscode_module.setup_compat_plugins()
  end
end
