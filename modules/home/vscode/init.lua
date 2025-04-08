-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Import modules
local vscode = require('vscode')
local modes = require('config.modes')
local keybindings = require('config.keybindings')
local utils = require('config.utils')
local mappings = require('config.mappings')

-- Performance options
vim.opt.ttimeoutlen = 0
vim.opt.updatetime = 100
vim.opt.timeoutlen = 300
vim.opt.virtualedit = "block"
vim.opt.inccommand = ""
vim.opt.jumpoptions = "stack"

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