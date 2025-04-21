-- WARNING: AUTO-GENERATED FILE. DO NOT EDIT.
-- Template for VSCode Neovim init, based on init.lua

vim.g.vscode = true

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

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { noremap = true, silent = true })

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", ":", ":", { noremap = true, desc = "Command mode" })

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

-- VSCode-specific settings
local function setup_vscode_settings()
  vim.notify("SysInit -- VSCode Neovim integration detected", vim.log.levels.INFO)
end

setup_common_settings()
setup_vscode_settings()

local module_loader = require("core.module_loader")

-- determine module loading system
local module_system = {
  editor = {
    "vscode",
  },
  ui = {
  },
  tools = {
  },
}

local function collect_plugin_specs()
  return module_loader.get_plugin_specs(module_system)
end

require("lazy").setup(collect_plugin_specs())

module_loader.setup_modules(module_system)

-- VSCode Neovim compatibility: inline from lua/modules/editor/vscode.lua
-- 1) Map of Neovim commands to VSCode actions
local cmd_map = {
  w      = "workbench.action.files.save",
  wa     = "workbench.action.files.saveAll",
  q      = "workbench.action.closeActiveEditor",
  qa     = "workbench.action.quit",
  enew   = "workbench.action.files.newUntitledFile",
  bdelete= "workbench.action.closeActiveEditor",
  bn     = "workbench.action.nextEditor",
  bp     = "workbench.action.previousEditor",
  split  = "workbench.action.splitEditorDown",
  vsplit = "workbench.action.splitEditorRight",
}

-- 2) Which-key style keybindings
local keybindings = {
  f = {
    name = "🔍 Find",
    bindings = {
      { key = "f", description = "Find Files",    action = "search-preview.quickOpenWithPreview" },
      { key = "g", description = "Find in Files", action = "workbench.action.findInFiles" },
      { key = "b", description = "Find Buffers",  action = "workbench.action.showAllEditors" },
      { key = "s", description = "Find Symbols",  action = "workbench.action.showAllSymbols" },
      { key = "r", description = "Recent Files",  action = "workbench.action.openRecent" },
    },
  },
  w = {
    name = "🪟 Window",
    bindings = {
      -- ... fill in from original module
    },
  },
  -- TODO: add remaining prefixes: u, b, g, c, t, a, s
}

-- TODO: inline utility functions, write_prompt/status, map_cmd, prompt menu logic, and mappings