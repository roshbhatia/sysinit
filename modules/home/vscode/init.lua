-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opts = { noremap = true, silent = true }
local vscode = require("vscode")

-- Cache for menus
local cache = {
    menu_items = {}
}

-- Keybinding definitions with icons
local keybindings = {
    f = {
        name = "󰈔 Files",
        bindings = {
            { key = "f", description = "󰈞 Find File", action = "workbench.action.quickOpen" },
            { key = "p", description = "󰈄 Preview File", action = "search-preview.quickOpenWithPreview" },
            { key = "r", description = "󰋚 Recent Files", action = "workbench.action.openRecent" },
            { key = "s", description = "󰑒 Save File", action = "workbench.action.files.save" },
            { key = "n", description = "󰟒 New File", action = "workbench.action.files.newUntitledFile" }
        }
    },
    b = {
        name = "󰓩 Buffers",
        bindings = {
            { key = "b", description = "󰋚 Switch Buffer", action = "workbench.action.showAllEditors" },
            { key = "d", description = "󰅖 Close Buffer", action = "workbench.action.closeActiveEditor" },
            { key = "n", description = "󰜵 Next Buffer", action = "workbench.action.nextEditor" },
            { key = "p", description = "󰜮 Previous Buffer", action = "workbench.action.previousEditor" }
        }
    },
    s = {
        name = "󰍉 Search",
        bindings = {
            { key = "f", description = "󰱽 Find in Files", action = "workbench.action.findInFiles" },
            { key = "w", description = "󰱽 Find Word", action = "actions.find" },
            { key = "r", description = "󰛔 Replace in Files", action = "workbench.action.replaceInFiles" }
        }
    },
    g = {
        name = " Git",
        bindings = {
            { key = "s", description = "󰊢 Status", action = "workbench.scm.focus" },
            { key = "p", description = "󰶮 Pull", action = "git.pull" },
            { key = "P", description = "󰶯 Push", action = "git.push" },
            { key = "b", description = "󰘬 Branches", action = "git.checkout" }
        }
    },
    w = {
        name = "󱂬 Window",
        bindings = {
            { key = "v", description = "󰯍 Split Vertical", action = "workbench.action.splitEditorRight" },
            { key = "h", description = "󰯎 Split Horizontal", action = "workbench.action.splitEditorDown" },
            { key = "q", description = "󰅙 Close Window", action = "workbench.action.closeActiveEditor" }
        }
    },
    e = {
        name = "󰌵 Editor",
        bindings = {
            { key = "e", description = "󰏘 Explorer", action = "workbench.view.explorer" },
            { key = "f", description = "󰉨 Focus Editor", action = "workbench.action.focusActiveEditorGroup" },
            { key = "z", description = "󰁌 Zen Mode", action = "workbench.action.toggleZenMode" }
        }
    }
}

-- Setup mode display in status bar
local function update_mode_display()
    local modes = {
        ['n'] = { text = 'NORMAL', color = '#98c379' },
        ['i'] = { text = 'INSERT', color = '#61afef' },
        ['v'] = { text = 'VISUAL', color = '#c678dd' },
        ['V'] = { text = 'V-LINE', color = '#c678dd' },
        [''] = { text = 'V-BLOCK', color = '#c678dd' },
        ['R'] = { text = 'REPLACE', color = '#e06c75' },
        ['s'] = { text = 'SELECT', color = '#e5c07b' },
        ['S'] = { text = 'S-LINE', color = '#e5c07b' },
        [''] = { text = 'S-BLOCK', color = '#e5c07b' },
        ['c'] = { text = 'COMMAND', color = '#56b6c2' },
        ['t'] = { text = 'TERMINAL', color = '#98c379' }
    }
    
    local current_mode = vim.api.nvim_get_mode().mode
    local mode_data = modes[current_mode] or modes['n']
    
    -- Clear existing and create new status bar
    vscode.eval([[
        if (globalThis.modeStatusBar) {
            globalThis.modeStatusBar.dispose();
        }
        const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
        statusBar.text = args.text;
        statusBar.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
        statusBar.color = args.color;
        statusBar.show();
        globalThis.modeStatusBar = statusBar;
    ]], {
        timeout = 1000,
        args = {
            text = mode_data.text,
            color = mode_data.color
        }
    })
end

-- Create autocmd to update mode display
vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    callback = function()
        update_mode_display()
    end,
})

-- Initial mode display
update_mode_display()

-- Initialize menu state
local menu_state = {
    current_group = nil
}

-- Format keybinding items for QuickPick
local function format_menu_items(group)
    local items = {}
    for _, binding in ipairs(group.bindings) do
        table.insert(items, {
            label = binding.key,
            description = binding.description,
            action = binding.action
        })
    end
    return items
end

-- Format menu items with proper indentation and grouping
local function format_root_menu_items()
    if next(cache.menu_items) ~= nil then
        return cache.menu_items
    end
    
    local items = {}
    for key, group in pairs(keybindings) do
        -- Add group header
        table.insert(items, {
            label = key,
            description = group.name,
            isGroup = true,
            key = key
        })
        
        -- Add group items indented
        for _, binding in ipairs(group.bindings) do
            table.insert(items, {
                label = key .. binding.key,
                description = binding.description,
                action = binding.action,
                isGroupItem = true
            })
        end
    end
    
    cache.menu_items = items
    return items
end

-- Show the WhichKey menu using QuickPick
local function show_menu(group)
    local items
    if group then
        items = format_menu_items(group)
    else
        items = format_root_menu_items()
    end
    
    vscode.eval([[
        if (globalThis.quickPick) {
            globalThis.quickPick.dispose();
        }
        
        const quickPick = vscode.window.createQuickPick();
        quickPick.items = args.items.map(item => ({
            label: item.isGroup 
                ? `$(chevron-right) ${item.label}` 
                : item.isGroupItem 
                    ? `  $(key) ${item.label}` 
                    : `$(key) ${item.label}`,
            description: item.description,
            action: item.action,
            key: item.key
        }));
        
        quickPick.title = args.title;
        quickPick.placeholder = args.placeholder;
        
        quickPick.onDidAccept(() => {
            const selected = quickPick.selectedItems[0];
            if (selected) {
                if (selected.action) {
                    vscode.commands.executeCommand(selected.action);
                }
            }
            quickPick.hide();
            quickPick.dispose();
        });
        
        quickPick.onDidHide(() => {
            quickPick.dispose();
        });
        
        globalThis.quickPick = quickPick;
        quickPick.show();
    ]], { 
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

-- Hide the WhichKey menu
local function hide_menu()
    vscode.eval([[
        if (globalThis.quickPick) {
            globalThis.quickPick.hide();
            globalThis.quickPick.dispose();
            globalThis.quickPick = undefined;
        }
    ]], { timeout = 1000 })
end

-- Register root menu for leader key alone
vim.keymap.set("n", "<leader>", function()
    show_menu()
end, opts)

-- Enhanced keybinding handler
local function handle_group(prefix, group)
    vim.keymap.set("n", prefix, function()
        show_menu(group)
    end, opts)

    for _, binding in ipairs(group.bindings) do
        vim.keymap.set("n", prefix .. binding.key, function()
            hide_menu()
            vscode.action(binding.action)
        end, opts)
    end
end

-- Register all keybinding groups
for prefix, group in pairs(keybindings) do
    handle_group("<leader>" .. prefix, group)
end

-- Auto-hide menu on mode changes
vim.api.nvim_create_autocmd({"ModeChanged", "CursorMoved"}, {
    callback = hide_menu
})

-- Basic navigation
vim.keymap.set("n", "<C-h>", function() vscode.action("workbench.action.navigateLeft") end, opts)
vim.keymap.set("n", "<C-j>", function() vscode.action("workbench.action.navigateDown") end, opts)
vim.keymap.set("n", "<C-k>", function() vscode.action("workbench.action.navigateUp") end, opts)
vim.keymap.set("n", "<C-l>", function() vscode.action("workbench.action.navigateRight") end, opts)

-- Visual mode mappings
vim.keymap.set("v", "<", "<gv^", opts)
vim.keymap.set("v", ">", ">gv^", opts)
vim.keymap.set("v", "p", "pgvy", opts)