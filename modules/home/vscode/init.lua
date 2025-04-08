-- VSCode specific Neovim configuration
local opts = { noremap = true, silent = true }
local vscode = require("vscode")

-- Initialize keybinding display state
local display_state = {
    timer = nil,
    current_menu = nil,
    in_preview = false,
    last_group = nil
}

-- Create the webview panel for our menu
local function create_menu_js(content)
    return vscode.eval([[
        const panel = vscode.window.createWebviewPanel(
            'whichkeyMenu',
            'Key Bindings',
            { viewColumn: vscode.ViewColumn.One, preserveFocus: true },
            {
                enableScripts: true,
                retainContextWhenHidden: true
            }
        );

        // Style the webview
        panel.webview.html = `
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {
                        padding: 0;
                        margin: 0;
                        background-color: var(--vscode-editor-background);
                        color: var(--vscode-editor-foreground);
                        font-family: var(--vscode-editor-font-family);
                        font-size: var(--vscode-editor-font-size);
                    }
                    .menu-container {
                        padding: 1rem;
                        animation: slideDown 0.2s ease-out;
                    }
                    .binding {
                        padding: 0.2rem 0;
                        display: flex;
                        align-items: center;
                    }
                    .key {
                        color: var(--vscode-textPreformat-foreground);
                        margin-right: 1rem;
                    }
                    .description {
                        color: var(--vscode-descriptionForeground);
                    }
                    @keyframes slideDown {
                        from { transform: translateY(-100%); }
                        to { transform: translateY(0); }
                    }
                </style>
            </head>
            <body>
                <div class="menu-container">
                    ${args.content}
                </div>
            </body>
            </html>
        `;

        // Auto-hide after 3 seconds
        setTimeout(() => {
            panel.dispose();
        }, 3000);

        // Store panel reference globally so we can dispose it later
        if (globalThis.currentPanel) {
            globalThis.currentPanel.dispose();
        }
        globalThis.currentPanel = panel;

        return panel;
    ]], { args = { content = content } })
end

-- Format menu content as HTML
local function format_menu_html(group, direction)
    local html = string.format("<h2 style='margin-top: 0;'>%s</h2>", group.name)
    
    if direction then
        local arrow = direction == "next" and "→" or "←"
        html = html .. string.format("<div style='margin-bottom: 1rem;'>%s Group Navigation %s</div>", arrow, arrow)
    end
    
    for _, binding in ipairs(group.bindings) do
        local preview_indicator = binding.preview and " 󰄾" or ""
        html = html .. string.format(
            "<div class='binding'><span class='key'>%s</span><span class='description'>%s%s</span></div>",
            binding.key,
            binding.description,
            preview_indicator
        )
    end
    
    html = html .. [[
        <div style='margin-top: 1rem; color: var(--vscode-descriptionForeground);'>
            <div>⌨️ Controls:</div>
            <div>• <span class='key'>esc</span> close menu</div>
            <div>• <span class='key'>tab</span> next group</div>
            <div>• <span class='key'>shift+tab</span> previous group</div>
            <div>• <span class='key'>ctrl+p</span> toggle preview</div>
        </div>
    ]]
    
    return html
end

-- Show menu using VSCode webview
local function show_menu(group, direction)
    if display_state.timer then
        vim.fn.timer_stop(display_state.timer)
    end
    
    local html_content = format_menu_html(group, direction)
    create_menu_js(html_content)
    
    display_state.current_menu = group.name
    display_state.timer = vim.fn.timer_start(3000, function()
        vscode.eval("if (globalThis.currentPanel) { globalThis.currentPanel.dispose(); }")
        display_state.current_menu = nil
    end)
end

-- Hide menu
local function hide_menu()
    if display_state.timer then
        vim.fn.timer_stop(display_state.timer)
    end
    vscode.eval("if (globalThis.currentPanel) { globalThis.currentPanel.dispose(); }")
    display_state.current_menu = nil
end

-- Basic setup
vim.keymap.set("n", "<SPACE>", "<NOP>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.clipboard = vim.g.vscode_clipboard
vim.opt.clipboard = "unnamedplus"

-- Keybinding definitions with Nerd Font icons and organized groups
local keybindings = {
    f = {
        name = "󰈔 Files",
        bindings = {
            { key = "f", description = "󰈞 Find File", action = "workbench.action.quickOpen" },
            { key = "p", description = "󰈄 Preview File", action = "search-preview.quickOpenWithPreview", preview = true },
            { key = "r", description = "󰋚 Recent Files", action = "search-preview.showAllEditorsByMostRecentlyUsed", preview = true },
            { key = "s", description = "󰑒 Save File", action = "workbench.action.files.save" },
            { key = "n", description = "󰟒 New File", action = "workbench.action.files.newUntitledFile" },
            { key = "R", description = "󰑕 Rename File", action = "workbench.files.action.showActiveFileInExplorer" },
            { key = "m", description = "󰉃 Move File", action = "workbench.files.action.moveFile" },
            { key = "y", description = "󰆏 Copy Path", action = "workbench.action.files.copyPathOfActiveFile" },
            { key = "x", description = "󰗑 Delete File", action = "workbench.files.action.moveFileToTrash" }
        }
    },
    b = {
        name = "󰓩 Buffers",
        bindings = {
            { key = "b", description = "󰋚 Switch Buffer", action = "workbench.action.showAllEditors" },
            { key = "p", description = "󰐊 Pin Editor", action = "workbench.action.pinEditor" },
            { key = "u", description = "󰐃 Unpin Editor", action = "workbench.action.unpinEditor" },
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
            { key = "r", description = "󰛔 Replace in Files", action = "workbench.action.replaceInFiles" },
            { key = "s", description = "󰓡 Search Symbol", action = "workbench.action.showAllSymbols" }
        }
    },
    g = {
        name = " Git",
        bindings = {
            { key = "s", description = "󰊢 Status", action = "workbench.scm.focus" },
            { key = "p", description = "󰶮 Pull", action = "git.pull" },
            { key = "P", description = "󰶯 Push", action = "git.push" },
            { key = "b", description = "󰘬 Branches", action = "git.checkout" },
            { key = "l", description = "󰶾 Log", action = "git.viewHistory" },
            { key = "c", description = "󰊢 Commit", action = "git.commit" }
        }
    },
    w = {
        name = "󱂬 Window",
        bindings = {
            { key = "v", description = "󰯍 Split Vertical", action = "workbench.action.splitEditorRight" },
            { key = "h", description = "󰯎 Split Horizontal", action = "workbench.action.splitEditorDown" },
            { key = "q", description = "󰅙 Close Window", action = "workbench.action.closeActiveEditor" },
            { key = "o", description = "󱡴 Close Others", action = "workbench.action.closeOtherEditors" },
            { key = "t", description = "󰓩 Toggle Sidebar", action = "workbench.action.toggleSidebarVisibility" }
        }
    },
    l = {
        name = "󰒕 LSP",
        bindings = {
            { key = "r", description = "󰑕 Rename", action = "editor.action.rename" },
            { key = "d", description = "󰯻 Definition", action = "editor.action.revealDefinition" },
            { key = "R", description = "󰈇 References", action = "editor.action.goToReferences" },
            { key = "a", description = "󰏒 Actions", action = "editor.action.quickFix" },
            { key = "f", description = "󱁤 Format", action = "editor.action.formatDocument" }
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

-- Enhanced keybinding handler with webview menu display
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

-- Add more descriptive hover states
vim.api.nvim_create_autocmd({"CursorHold"}, {
    callback = function()
        local key = vim.fn.getcharstr()
        if vim.startswith(key, "<leader>") then
            local prefix = string.sub(key, #"<leader>" + 1, #"<leader>" + 1)
            local group = keybindings[prefix]
            if group then
                show_menu(group)
            end
        end
    end
})

-- Clean up preview when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
        if display_state.in_preview then
            vscode.action("workbench.action.closePreviewEditor")
            display_state.in_preview = false
        end
    end
})

-- Command preview functionality
vim.keymap.set("n", "<C-p>", function()
    vscode.action("workbench.action.quickOpenNavigateNextInFilePicker")
end, opts)

vim.keymap.set("n", "<C-n>", function()
    vscode.action("workbench.action.quickOpenNavigatePreviousInFilePicker")
end, opts)

-- Add fuzzy finder preview toggle
vim.keymap.set("n", "<C-y>", function()
    if display_state.in_preview then
        vscode.action("workbench.action.closePreviewEditor")
        display_state.in_preview = false
    else
        vscode.action("workbench.action.toggleEditorPreview")
        display_state.in_preview = true
    end
end, opts)

-- Quick navigation between groups
vim.keymap.set("n", "<Tab>", function()
    if display_state.current_menu then
        local current_prefix = nil
        for prefix, _ in pairs(keybindings) do
            if display_state.current_menu:find(keybindings[prefix].name) then
                current_prefix = prefix
                break
            end
        end
        
        if current_prefix then
            local next_prefix = nil
            local found = false
            for prefix, _ in pairs(keybindings) do
                if found then
                    next_prefix = prefix
                    break
                end
                if prefix == current_prefix then
                    found = true
                end
            end
            
            if not next_prefix then
                next_prefix = next(keybindings)
            end
            
            show_menu(keybindings[next_prefix], "next")
        end
    end
end, opts)

vim.keymap.set("n", "<S-Tab>", function()
    if display_state.current_menu then
        local current_prefix = nil
        for prefix, _ in pairs(keybindings) do
            if display_state.current_menu:find(keybindings[prefix].name) then
                current_prefix = prefix
                break
            end
        end
        
        if current_prefix then
            local prev_prefix = nil
            local last_prefix = nil
            for prefix, _ in pairs(keybindings) do
                if prefix == current_prefix then
                    if prev_prefix then
                        show_menu(keybindings[prev_prefix], "previous")
                        return
                    end
                end
                prev_prefix = prefix
                last_prefix = prefix
            end
            
            -- Wrap around to the last group
            show_menu(keybindings[last_prefix], "previous")
        end
    end
end, opts)

-- Status line integration
vim.api.nvim_create_autocmd({"BufEnter", "WinEnter"}, {
    callback = function()
        if display_state.current_menu then
            local current_prefix = nil
            for prefix, group in pairs(keybindings) do
                if display_state.current_menu:find(group.name) then
                    current_prefix = prefix
                    break
                end
            end
            
            if current_prefix then
                vim.o.statusline = string.format(" %s ", keybindings[current_prefix].name)
            end
        else
            vim.o.statusline = ""
        end
    end
})

-- Basic navigation
vim.keymap.set("n", "<C-h>", function() vscode.action("workbench.action.navigateLeft") end, opts)
vim.keymap.set("n", "<C-j>", function() vscode.action("workbench.action.navigateDown") end, opts)
vim.keymap.set("n", "<C-k>", function() vscode.action("workbench.action.navigateUp") end, opts)
vim.keymap.set("n", "<C-l>", function() vscode.action("workbench.action.navigateRight") end, opts)

-- Visual mode enhancements
vim.keymap.set("v", "<", "<gv^", opts)
vim.keymap.set("v", ">", ">gv^", opts)
vim.keymap.set("v", "p", "pgvy", opts)

-- Quick navigation
vim.keymap.set("n", "]d", function() vscode.action("editor.action.marker.next") end, opts)
vim.keymap.set("n", "[d", function() vscode.action("editor.action.marker.prev") end, opts)
vim.keymap.set("n", "gr", function() vscode.action("editor.action.goToReferences") end, opts)
vim.keymap.set("n", "<S-k>", function() vscode.action("editor.action.showHover") end, opts)

-- Configure cursor appearance
vim.opt.guicursor = table.concat({
    "n-c:block-blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
    "i-ci-ve:ver25-blinkwait400-blinkoff250-blinkon500-CursorIM/lCursor",
    "v-sm:block-blinkwait175-blinkoff150-blinkon175-Visual/lCursor",
    "r-cr-o:hor20-blinkwait700-blinkoff400-blinkon250-CursorRM/lCursor"
}, ",")

-- Cursor highlighting
vim.api.nvim_create_autocmd({"ColorScheme", "VimEnter"}, {
    callback = function()
        vim.api.nvim_set_hl(0, "Cursor", { fg = "#282828", bg = "#fe8019" })
        vim.api.nvim_set_hl(0, "CursorIM", { fg = "#282828", bg = "#b8bb26" })
        vim.api.nvim_set_hl(0, "Visual", { fg = "#282828", bg = "#d3869b" })
        vim.api.nvim_set_hl(0, "CursorRM", { fg = "#282828", bg = "#fb4934" })
    end
})