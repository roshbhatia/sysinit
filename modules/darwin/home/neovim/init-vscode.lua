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
 
-- Helper functions for file output and parity checking
local info = debug.getinfo(1, 'S')
local script_path = info.source:sub(2)
local script_dir = vim.fn.fnamemodify(script_path, ':p:h')
local root_dir = vim.fn.fnamemodify(script_dir .. '/../../../', ':p')
local utils = {
  prompt_file  = root_dir .. 'prompt.md',
  status_file  = root_dir .. 'status.md',
  actions_file = root_dir .. 'vscode/actions.txt',
}

local function write_file(path, lines)
  local f, err = io.open(path, 'w')
  if not f then
    vim.notify('Error opening file: ' .. path .. ': ' .. err, vim.log.levels.ERROR)
    return
  end
  for _, line in ipairs(lines) do f:write(line .. '\n') end
  f:close()
end

local function write_prompt(title, placeholder, items)
  local lines = {
    '# Which Key Prompt', '',
    '**Title**: ' .. title, '',
    '**Placeholder**: ' .. placeholder, '',
    'Items:', ''
  }
  for _, item in ipairs(items) do
    if item.kind == -1 then
      table.insert(lines, '- --- separator ---')
    else
      table.insert(lines, string.format(
        '- `%s`: %s (action: %s)',
        item.label, item.description or '', item.action or ''
      ))
    end
  end
  write_file(utils.prompt_file, lines)
end

local function write_status(entries)
  local lines = { '# VSCode Neovim Parity Status', '' }
  for _, e in ipairs(entries) do table.insert(lines, '- ' .. e) end
  write_file(utils.status_file, lines)
end

local function check_parity()
  local entries = {}
  local valid = {}
  local af = io.open(utils.actions_file, 'r')
  if af then
    for line in af:lines() do valid[line] = true end
    af:close()
  else
    table.insert(entries, 'Unable to open actions file: ' .. utils.actions_file)
    write_status(entries)
    return
  end
  for cmd, action in pairs(cmd_map) do
    if not valid[action] then
      local msg = string.format("Invalid action '%s' for command '%s'", action, cmd)
      vim.notify(msg, vim.log.levels.WARN)
      table.insert(entries, msg)
    end
  end
  for prefix, group in pairs(keybindings) do
    for _, b in ipairs(group.bindings) do
      if not valid[b.action or ''] then
        local msg = string.format("Invalid action '%s' in bindings for '%s'", b.action, prefix)
        vim.notify(msg, vim.log.levels.WARN)
        table.insert(entries, msg)
      end
    end
  end
  if #entries == 0 then table.insert(entries, 'All VSCode actions are valid.') end
  write_status(entries)
end

local function map_cmd(mode, lhs, cmd, opts)
  opts = opts or { noremap = true, silent = true }
  local action = cmd_map[cmd]
  if action then
    local api = require('vscode')
    vim.keymap.set(mode, lhs, function() api.action(action) end, opts)
  else
    vim.keymap.set(mode, lhs, '<cmd>' .. cmd .. '<cr>', opts)
  end
end

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