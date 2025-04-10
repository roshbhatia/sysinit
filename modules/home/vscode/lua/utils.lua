local M = {}

-- Pre-generated eval strings for better performance
M.EVAL_STRINGS = {
    mode_display = [[
        if (globalThis.modeStatusBar) { globalThis.modeStatusBar.dispose(); }
        const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
        statusBar.text = args.text;
        statusBar.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
        statusBar.color = args.color;
        statusBar.show();
        globalThis.modeStatusBar = statusBar;
    ]],
    quickpick_menu = [[
        if (globalThis.quickPick) { globalThis.quickPick.dispose(); }
        const quickPick = vscode.window.createQuickPick();
        quickPick.items = args.items.map(item => ({
            label: item.isGroup ? `$(chevron-right) ${item.label}` : item.isGroupItem ? `  $(key) ${item.label}` : `$(key) ${item.label}`,
            description: item.description,
            action: item.action,
            key: item.key
        }));
        quickPick.title = args.title;
        quickPick.placeholder = args.placeholder;
        quickPick.onDidAccept(() => {
            const selected = quickPick.selectedItems[0];
            if (selected && selected.action) { vscode.commands.executeCommand(selected.action); }
            quickPick.hide();
            quickPick.dispose();
        });
        quickPick.onDidHide(() => quickPick.dispose());
        globalThis.quickPick = quickPick;
        quickPick.show();
    ]],
    hide_quickpick = [[
        if (globalThis.quickPick) {
            globalThis.quickPick.hide();
            globalThis.quickPick.dispose();
            globalThis.quickPick = undefined;
        }
    ]]
}

-- Cache menu items for better performance
M.menu_cache = {
    root_items = nil,
    group_items = {}
}

-- Menu state management
M.menu_state = {
    current_group = nil
}

-- Format menu items with proper indentation and grouping
function M.format_menu_items(group)
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

-- Create cache key for menu items
function M.create_menu_cache_key(items)
    return table.concat(vim.tbl_map(function(item)
        return item.key or item.label
    end, items), "_")
end

return M
