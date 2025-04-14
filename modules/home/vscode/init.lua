-- Get the directory of the current file for module loading
local function get_current_dir()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

-- Add the current directory to package.path
local current_dir = get_current_dir() or vim.fn.expand("%:p:h") .. "/"
package.path = current_dir .. "lua/?.lua;" .. current_dir .. "lua/?/init.lua;" .. package.path

-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Explicitly register space key to do nothing (prevents default space behavior)
vim.keymap.set('n', '<Space>', '<NOP>')

-- Import modules
local vscode = require('vscode')
local modes = require('modes')
local keybindings = require('keybindings')
local utils = require('utils')
local mappings = require('mappings')

-- Basic editor settings
vim.opt.number = true
vim.opt.cursorline = true
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
vim.opt.ttimeoutlen = 0
vim.opt.virtualedit = "block"
vim.opt.inccommand = ""
vim.opt.jumpoptions = "stack"

-- Scrolling
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Other options
vim.opt.mouse = "a"

-- Pre-generate mode strings
local mode_strings = {}
for mode, data in pairs(modes.MODE_DISPLAY) do
    mode_strings[mode] = string.format("Mode: %s", data.text)
end

-- Mode display management
local last_mode = nil
local function update_mode_display()
    local current_mode = vim.api.nvim_get_mode().mode
    if current_mode == last_mode then return end
    
    local mode_data = modes.MODE_DISPLAY[current_mode] or modes.MODE_DISPLAY.n
    vscode.eval(utils.EVAL_STRINGS.mode_display, {
        timeout = 1000,
        args = {
            text = mode_strings[current_mode] or mode_strings.n,
            color = mode_data.color
        }
    })
    last_mode = current_mode
end

-- Setup mode display autocmds
vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = '*',
    callback = update_mode_display
})

vim.api.nvim_create_autocmd('CmdlineEnter', {
    callback = function()
        vscode.eval(utils.EVAL_STRINGS.mode_display, {
            timeout = 1000,
            args = {
                text = "COMMAND",
                color = modes.MODE_DISPLAY.c.color
            }
        })
    end
})

-- WhichKey-like menu functionality
local function format_root_menu_items()
    if utils.menu_cache.root_items then
        return utils.menu_cache.root_items
    end
    
    local items = {}
    for key, group in pairs(keybindings.keybindings) do
        table.insert(items, {
            label = key,
            description = group.name,
            isGroup = true,
            key = key
        })
        
        for _, binding in ipairs(group.bindings) do
            table.insert(items, {
                label = key .. binding.key,
                description = binding.description,
                action = binding.action,
                isGroupItem = true
            })
        end
    end
    
    utils.menu_cache.root_items = items
    return items
end

local function show_menu(group)
    local items
    if group then
        items = utils.format_menu_items(group)
    else
        items = format_root_menu_items()
    end
    
    vscode.eval(utils.EVAL_STRINGS.quickpick_menu, { 
        timeout = 1000,
        args = { 
            items = items,
            title = group and group.name or "WhichKey Menu",
            placeholder = group 
                and 'Select an action or press <Esc> to cancel'
                or 'Select a group or action (groups shown with ▸)'
        }
    })
end

local function hide_menu()
    vscode.eval(utils.EVAL_STRINGS.hide_quickpick, { timeout = 1000 })
end

-- Register WhichKey-like menu
vim.keymap.set("n", "<leader>", function()
    show_menu()
end, { noremap = true, silent = true })

-- Register keybinding groups
local function handle_group(prefix, group)
    vim.keymap.set("n", prefix, function()
        show_menu(group)
    end, { noremap = true, silent = true })

    for _, binding in ipairs(group.bindings) do
        vim.keymap.set("n", prefix .. binding.key, function()
            hide_menu()
            vscode.action(binding.action)
        end, { noremap = true, silent = true })
    end
end

for prefix, group in pairs(keybindings.keybindings) do
    handle_group("<leader>" .. prefix, group)
end

-- Auto-hide menu on mode changes
vim.api.nvim_create_autocmd({"ModeChanged", "CursorMoved"}, {
    callback = hide_menu
})

-- Initialize base mappings
mappings.setup()

-- Initialize with mode display
update_mode_display()

-- Trigger initialization complete
vim.api.nvim_exec_autocmds('User', {pattern = 'VSCodeInitialized'})
