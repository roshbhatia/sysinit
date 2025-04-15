--[[---------------------------------------
             VSCode Neovim Configuration
             
  Author: Rosh Bhatia
  Repo: github.com/roshbhatia/sysinit
  
  This allows using Neovim controls from within VSCode
  with the VSCode-Neovim extension.
-----------------------------------------]]

-- Set VSCode global flag so our main config knows we're in VSCode
vim.g.vscode = true

-- Add current directory to package path
local function get_current_dir()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

local current_dir = get_current_dir() or vim.fn.expand("%:p:h") .. "/"
package.path = current_dir .. "lua/?.lua;" .. current_dir .. "lua/?/init.lua;" .. package.path

-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic settings
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
vim.opt.ttimeoutlen = 0

-- Scrolling
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Other options
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"  -- Use system clipboard

-- Try to load modules from our main Neovim config first
local neovim_path = vim.fn.expand("~/.config/nvim")
if vim.fn.isdirectory(neovim_path) == 1 then
  -- Add the main Neovim config to runtimepath
  vim.opt.rtp:prepend(neovim_path)
  
  -- Try to load a subset of our Neovim config
  local status, vscode = pcall(require, "core.vscode")
  if status then
    -- Use our centralized VSCode integration
    vscode.setup()
  end
end

-- VSCode-specific settings
local vscode = require('vscode')
local mappings = require('mappings')

-- Define VSCode command wrapper function
local function vscode_command(command)
  return function()
    vscode.call(command)
  end
end

-- Set up VSCode-specific keybindings
local function setup_vscode_keymaps()
  -- Set Space+Enter as command line trigger
  vim.keymap.set('n', '<Space><CR>', ':', { noremap = true })
  
  -- Navigation
  vim.keymap.set('n', 'j', 'gj', { silent = true })
  vim.keymap.set('n', 'k', 'gk', { silent = true })
  
  -- Editing
  vim.keymap.set('n', '<leader>cc', vscode_command('editor.action.commentLine'), { desc = "Toggle Comment" })
  vim.keymap.set('v', '<leader>cc', vscode_command('editor.action.commentLine'), { desc = "Toggle Comment" })
  
  -- Find files / search
  vim.keymap.set('n', '<leader>ff', vscode_command('workbench.action.quickOpen'), { desc = "Find Files" })
  vim.keymap.set('n', '<leader>fg', vscode_command('workbench.action.findInFiles'), { desc = "Find in Files" })
  vim.keymap.set('n', '<leader>fs', vscode_command('actions.find'), { desc = "Search in File" })
  
  -- LSP/Code actions
  vim.keymap.set('n', '<leader>ca', vscode_command('editor.action.quickFix'), { desc = "Code Actions" })
  vim.keymap.set('n', '<leader>cr', vscode_command('editor.action.rename'), { desc = "Rename Symbol" })
  vim.keymap.set('n', 'gd', vscode_command('editor.action.revealDefinition'), { desc = "Go to Definition" })
  vim.keymap.set('n', 'gr', vscode_command('references-view.find'), { desc = "Find References" })
  
  -- UI
  vim.keymap.set('n', '<leader>ue', vscode_command('workbench.action.toggleSidebarVisibility'), { desc = "Toggle Sidebar" })
  vim.keymap.set('n', '<leader>uf', vscode_command('workbench.action.toggleFullScreen'), { desc = "Toggle Fullscreen" })
  
  -- Terminal
  vim.keymap.set('n', '<leader>tt', vscode_command('workbench.action.terminal.toggleTerminal'), { desc = "Toggle Terminal" })
  
  -- Session management (using VSCode workspaces)
  vim.keymap.set('n', '<leader>ss', vscode_command('workbench.action.files.saveWorkspaceAs'), { desc = "Save Workspace" })
  vim.keymap.set('n', '<leader>sl', vscode_command('workbench.action.openRecent'), { desc = "Load Workspace" })
  vim.keymap.set('n', '<leader>sd', vscode_command('workbench.action.closeFolder'), { desc = "Close Workspace" })
end

-- Initialize our VSCode-specific mappings
setup_vscode_keymaps()

-- Also load our common mappings, which have fallbacks for VSCode
mappings.setup()

-- Trigger initialization complete
vim.api.nvim_exec_autocmds('User', {pattern = 'VSCodeInitialized'})
