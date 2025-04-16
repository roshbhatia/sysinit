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

-- Common settings (for both regular Neovim and VSCode)
local function setup_common_settings()
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

  -- Scrolling
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8

  -- Other options
  vim.opt.mouse = "a"
  vim.opt.clipboard = "unnamedplus"  -- Use system clipboard
end

-- Regular Neovim-only settings
local function setup_neovim_settings()
  -- UI settings
  vim.opt.number = true
  vim.opt.cursorline = true
  vim.opt.signcolumn = "yes"
  vim.opt.termguicolors = true
  vim.opt.showmode = false  -- Hide mode since we use lualine
  vim.opt.lazyredraw = true
  
  -- Folding
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  vim.opt.foldenable = false
  vim.opt.foldlevel = 99

  -- UI improvements
  vim.opt.pumheight = 10        -- Limit completion menu height
  vim.opt.cmdheight = 1         -- More space for displaying messages
  vim.opt.hidden = true         -- Enable background buffers
  vim.opt.showtabline = 2       -- Always show tabline
  vim.opt.shortmess:append("c") -- Don't show completion messages
  vim.opt.completeopt = { "menuone", "noselect" }
end

-- VSCode-specific settings and keybindings
local function setup_vscode_settings()
  -- Apply VSCode-specific settings
  vim.notify("VSCode Neovim integration detected", vim.log.levels.INFO)
  
  -- Configure compatible plugins
  -- We will handle this through the VSCode module
  -- to allow proper modularization
end

-- Apply settings based on environment
setup_common_settings()
if vim.g.vscode then
  setup_vscode_settings()
else
  setup_neovim_settings()
end

-- Define different module sets for regular Neovim and VSCode
local module_system

-- Regular Neovim modules
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
      "profile",
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

-- Collect plugin specs from all modules
local function collect_plugin_specs()
  local specs = {}
  
  -- Which-key is already configured via its module, no need to add it again

  -- Process modules in specific order
  local categories = {"editor", "ui", "tools"}
  
  for _, category in ipairs(categories) do
    for _, module_name in ipairs(module_system[category]) do
      local ok, module = pcall(require, "modules." .. category .. "." .. module_name)
      if ok and module.plugins then
        vim.list_extend(specs, module.plugins)
      end
    end
  end
  
  -- Add common plugins like LSP and completion
  if not vim.g.vscode then
    -- Git integration
    table.insert(specs, {
      "lewis6991/gitsigns.nvim",
      config = function()
        require("gitsigns").setup()
      end
    })
  end
  
  return specs
end

-- Setup Lazy.nvim with collected specs
require("lazy").setup(collect_plugin_specs())

-- Initialize VSCode-specific plugin compatibility settings if needed
if vim.g.vscode then
  -- After plugins are loaded, set up VSCode compatibility for plugins
  -- that need special handling in VSCode environment
  local vscode_module = require("modules.editor.vscode")
  if vscode_module and vscode_module.setup_compat_plugins then
    vscode_module.setup_compat_plugins()
  end
end
