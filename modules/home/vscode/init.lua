-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opts = { noremap = true, silent = true }
local vscode = require("vscode")

-- Setup mode display in status bar
local function update_mode_display()
    local modes = {
        ['n'] = { text = 'NORMAL', color = '#98c379' },  -- Green
        ['i'] = { text = 'INSERT', color = '#61afef' },  -- Blue
        ['v'] = { text = 'VISUAL', color = '#c678dd' },  -- Purple
        ['V'] = { text = 'V-LINE', color = '#c678dd' },  -- Purple
        [''] = { text = 'V-BLOCK', color = '#c678dd' }, -- Purple
        ['R'] = { text = 'REPLACE', color = '#e06c75' }, -- Red
        ['s'] = { text = 'SELECT', color = '#e5c07b' },  -- Yellow
        ['S'] = { text = 'S-LINE', color = '#e5c07b' },  -- Yellow
        [''] = { text = 'S-BLOCK', color = '#e5c07b' }, -- Yellow
        ['c'] = { text = 'COMMAND', color = '#56b6c2' }, -- Cyan
        ['t'] = { text = 'TERMINAL', color = '#98c379' } -- Green
    }
    
    local current_mode = vim.api.nvim_get_mode().mode
    local mode_data = modes[current_mode] or modes['n']
    
    vscode.eval([[
        const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
        statusBar.text = args.text;
        statusBar.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
        statusBar.color = args.color;
        statusBar.show();
        
        // Store the status bar item globally so we can update it
        if (globalThis.modeStatusBar) {
            globalThis.modeStatusBar.dispose();
        }
        globalThis.modeStatusBar = statusBar;
    ]], {
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
    current_group = nil,
    quickpick = nil
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

-- Show the WhichKey menu using QuickPick
local function show_menu(group)
    -- Create QuickPick items
    local items = format_menu_items(group)
    
    -- Use VSCode's showQuickPick API
    vscode.eval([[
        const items = args.items;
        const quickPick = vscode.window.createQuickPick();
        quickPick.items = items.map(item => ({
            label: `$(key) ${item.label}`,
            description: item.description,
            action: item.action
        }));
        quickPick.title = args.title;
        quickPick.placeholder = 'Select an action or press <Esc> to cancel';
        
        // Handle selection
        quickPick.onDidAccept(() => {
            const selected = quickPick.selectedItems[0];
            if (selected) {
                vscode.commands.executeCommand(selected.action);
            }
            quickPick.hide();
        });
        
        // Clean up on hide
        quickPick.onDidHide(() => {
            quickPick.dispose();
        });
        
        quickPick.show();
    ]], { 
        args = { 
            items = items,
            title = group.name
        } 
    })
    
    menu_state.current_group = group.name
end

-- Hide the WhichKey menu
local function hide_menu()
    if menu_state.current_group then
        vscode.eval([[
            // No explicit hide needed as the quickpick auto-disposes
        ]])
        menu_state.current_group = nil
    end
end

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