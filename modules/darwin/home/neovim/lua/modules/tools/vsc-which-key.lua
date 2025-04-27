local vscode = require('vscode')
local M = {}

local cache = {
    root_items = nil,
    group_items = {}
}

local MODE_DISPLAY = {
    n = {
        text = 'NORMAL',
        color = '#7aa2f7'
    },
    i = {
        text = 'INSERT',
        color = '#9ece6a'
    },
    v = {
        text = 'VISUAL',
        color = '#bb9af7'
    },
    V = {
        text = 'V-LINE',
        color = '#bb9af7'
    },
    ['\22'] = {
        text = 'V-BLOCK',
        color = '#bb9af7'
    },
    R = {
        text = 'REPLACE',
        color = '#f7768e'
    },
    s = {
        text = 'SELECT',
        color = '#ff9e64'
    },
    S = {
        text = 'S-LINE',
        color = '#ff9e64'
    },
    ['\19'] = {
        text = 'S-BLOCK',
        color = '#ff9e64'
    },
    c = {
        text = 'COMMAND',
        color = '#7dcfff'
    },
    t = {
        text = 'TERMINAL',
        color = '#73daca'
    }
}

local mode_strings = {}
local last_mode = nil

for mode, data in pairs(MODE_DISPLAY) do
    mode_strings[mode] = string.format("Mode: %s", data.text)
end

local EVAL_STRINGS = {
    mode_display = [[
        if (globalThis.modeStatusBar) { globalThis.modeStatusBar.dispose(); }
        const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
        statusBar.text = args.text;
        statusBar.color = args.color;
        statusBar.command = {
          command: 'vscode-neovim.lua',
          title: 'Toggle Neovim Mode',
          arguments: [
            args.mode === 'n'
              ? "vim.cmd('startinsert')"
              : "vim.cmd('stopinsert')"
          ]
        };
        statusBar.show();
        globalThis.modeStatusBar = statusBar;
    ]],
    quickpick_menu = [[
        const vscode = require('vscode');
        if (globalThis.quickPick) { globalThis.quickPick.dispose(); }
        
        const quickPick = vscode.window.createQuickPick();
        quickPick.items = args.items.map(item => ({
          label: item.isGroup ? `$(chevron-right) ${item.label}` : item.isGroupItem ? `  $(key) ${item.label}` : item.label,
          description: item.description,
          action: item.action,
          key: item.key,
          kind: item.kind,
          isGroup: item.isGroup
        }));
        quickPick.title = args.title;
        quickPick.placeholder = args.placeholder;
        
        let lastActiveItem = null;
        let autoExecuteTimer = null;
        const TIMEOUT_MS = 500;  // Timeout in milliseconds
        
        // Filter items based on input
        quickPick.onDidChangeValue((value) => {
          if (autoExecuteTimer) {
            clearTimeout(autoExecuteTimer);
          }
          
          // Get filtered items that match the input
          const matchingItems = quickPick.items.filter(item => 
            item.label.toLowerCase().startsWith(value.toLowerCase())
          );
          
          // If we have exactly one match and it's a leaf node
          if (matchingItems.length === 1 && !matchingItems[0].isGroup) {
            autoExecuteTimer = setTimeout(async () => {
              const item = matchingItems[0];
              if (item.action) {
                await vscode.commands.executeCommand(item.action);
                quickPick.hide();
                quickPick.dispose();
              }
            }, TIMEOUT_MS);
          }
        });
        
        quickPick.onDidChangeActive((items) => {
          const active = items[0];
          if (!active || active === lastActiveItem) return;
          lastActiveItem = active;
          
          // Auto-execute for leaf nodes (non-groups)
          if (active.action && !active.isGroup) {
            vscode.commands.executeCommand(active.action).then(() => {
              quickPick.hide();
              quickPick.dispose();
            });
          }
        });
        
        quickPick.onDidAccept(async () => {
          if (autoExecuteTimer) {
            clearTimeout(autoExecuteTimer);
          }
          
          const selected = quickPick.selectedItems[0];
          if (!selected) return;
          
          if (selected.isGroup) {
            return;
          }

          if (selected.action) {
            await vscode.commands.executeCommand(selected.action);
          }
          quickPick.hide();
          quickPick.dispose();
        });
        
        quickPick.onDidHide(() => {
          if (autoExecuteTimer) {
            clearTimeout(autoExecuteTimer);
          }
          quickPick.dispose();
        });
        
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

local keybindings = {
    f = {
        name = "󰀶 Find",
        bindings = {{
            key = "f",
            description = "Find Files",
            action = "search-preview.quickOpenWithPreview"
        }, {
            key = "g",
            description = "Find in Files",
            action = "workbench.action.findInFiles"
        }, {
            key = "b",
            description = "Find Buffers",
            action = "workbench.action.showAllEditors"
        }, {
            key = "s",
            description = "Find Symbols",
            action = "workbench.action.showAllSymbols"
        }, {
            key = "r",
            description = "Recent Files",
            action = "workbench.action.openRecent"
        }}
    },
    b = {
        name = "󱅄 Buffer",
        bindings = {{
            key = "n",
            description = "Next Buffer",
            action = "workbench.action.nextEditor"
        }, {
            key = "p",
            description = "Previous Buffer",
            action = "workbench.action.previousEditor"
        }, {
            key = "d",
            description = "Close Buffer",
            action = "workbench.action.closeActiveEditor"
        }, {
            key = "o",
            description = "Close Others",
            action = "workbench.action.closeOtherEditors"
        }}
    },
    c = {
        name = "󰘧 Code",
        bindings = {{
            key = "a",
            description = "Quick Fix",
            action = "editor.action.quickFix"
        }, {
            key = "r",
            description = "Rename Symbol",
            action = "editor.action.rename"
        }, {
            key = "f",
            description = "Format Document",
            action = "editor.action.formatDocument"
        }, {
            key = "d",
            description = "Go to Definition",
            action = "editor.action.revealDefinition"
        }, {
            key = "i",
            description = "Go to Implementation",
            action = "editor.action.goToImplementation"
        }, {
            key = "h",
            description = "Show Hover",
            action = "editor.action.showHover"
        }, {
            key = "c",
            description = "Toggle Comment",
            action = "editor.action.commentLine"
        }, {
            key = "R",
            description = "Find References",
            action = "editor.action.goToReferences"
        }}
    },
    g = {
        name = "󰊢 Git",
        bindings = {{
            key = "s",
            description = "Stage Hunk",
            action = "git.stage"
        }, {
            key = "S",
            description = "Stage Buffer",
            action = "git.stageAll"
        }, {
            key = "u",
            description = "Unstage Hunk",
            action = "git.unstage"
        }, {
            key = "U",
            description = "Unstage Buffer",
            action = "git.unstageAll"
        }, {
            key = "c",
            description = "Commit",
            action = "git.commit"
        }, {
            key = "p",
            description = "Push",
            action = "git.push"
        }, {
            key = "P",
            description = "Pull",
            action = "git.pull"
        }, {
            key = "d",
            description = "Diff This",
            action = "git.openChange"
        }, {
            key = "b",
            description = "Branches",
            action = "git.checkout"
        }, {
            key = "v",
            description = "Status (View)",
            action = "workbench.view.scm"
        }, {
            key = "j",
            description = "Next Change",
            action = "workbench.action.editor.nextChange"
        }, {
            key = "k",
            description = "Previous Change",
            action = "workbench.action.editor.previousChange"
        }}
    },
    w = {
        name = " Window",
        bindings = {{
            key = "h",
            description = "Focus Left Window",
            action = "workbench.action.focusLeftGroup"
        }, {
            key = "j",
            description = "Focus Lower Window",
            action = "workbench.action.focusDownGroup"
        }, {
            key = "k",
            description = "Focus Upper Window",
            action = "workbench.action.focusUpGroup"
        }, {
            key = "l",
            description = "Focus Right Window",
            action = "workbench.action.focusRightGroup"
        }, {
            key = "=",
            description = "Equal Size",
            action = "workbench.action.evenEditorWidths"
        }, {
            key = "_",
            description = "Max Height",
            action = "workbench.action.toggleEditorWidths"
        }, {
            key = "w",
            description = "Close Window",
            action = "workbench.action.closeActiveEditor"
        }, {
            key = "o",
            description = "Only Window",
            action = "workbench.action.closeOtherEditors"
        }, {
            key = "H",
            description = "Move Window Left",
            action = "workbench.action.moveEditorToLeftGroup"
        }, {
            key = "J",
            description = "Move Window Down",
            action = "workbench.action.moveEditorToBelowGroup"
        }, {
            key = "K",
            description = "Move Window Up",
            action = "workbench.action.moveEditorToAboveGroup"
        }, {
            key = "L",
            description = "Move Window Right",
            action = "workbench.action.moveEditorToRightGroup"
        }}
    },
    t = {
        name = "󰨚 Toggle",
        bindings = {{
            key = "e",
            description = "Explorer",
            action = "workbench.view.explorer"
        }, {
            key = "t",
            description = "Terminal",
            action = "workbench.action.terminal.toggleTerminal"
        }, {
            key = "p",
            description = "Problems",
            action = "workbench.actions.view.problems"
        }, {
            key = "o",
            description = "Outline",
            action = "outline.focus"
        }, {
            key = "c",
            description = "Chat",
            action = "workbench.action.chat.open"
        }, {
            key = "m",
            description = "Command Palette",
            action = "workbench.action.showCommands"
        }}
    },
    s = {
        name = "󰓩 Split",
        bindings = {{
            key = "s",
            description = "Split Horizontal",
            action = "workbench.action.splitEditorDown"
        }, {
            key = "v",
            description = "Split Vertical",
            action = "workbench.action.splitEditorRight"
        }}
    },
    a = {
        name = "󱚟 AI",
        bindings = {{
            key = "c",
            description = "Start Chat",
            action = "workbench.action.chat.open"
        }, {
            key = "i",
            description = "Inline Chat",
            action = "inlineChat.start"
        }, {
            key = "a",
            description = "Accept Changes",
            action = "inlineChat.acceptChanges"
        }, {
            key = "g",
            description = "Generate Commit",
            action = "github.copilot.git.generateCommitMessage"
        }}
    }
}

local function format_menu_items(group)
    local items = {}
    for _, binding in ipairs(group.bindings) do
        table.insert(items, {
            label = binding.key,
            description = binding.description,
            action = binding.action,
            key = binding.key,
            isGroup = false,
            isGroupItem = false
        })
    end
    return items
end

local function format_root_menu_items()
    if cache.root_items then
        return cache.root_items
    end

    local items = {}
    local lastCategory = nil

    for key, group in pairs(keybindings) do
        if lastCategory then
            table.insert(items, {
                label = "──────────────",
                kind = -1,
                isGroup = false,
                isGroupItem = false
            })
        end
        table.insert(items, {
            label = key,
            description = group.name,
            key = key,
            isGroup = true,
            isGroupItem = false
        })
        for _, binding in ipairs(group.bindings) do
            table.insert(items, {
                label = key .. binding.key,
                description = binding.description,
                action = binding.action,
                key = binding.key,
                isGroup = false,
                isGroupItem = true
            })
        end
        lastCategory = key
    end

    cache.root_items = items
    return items
end

local function show_menu(group)
    local ok, items = pcall(function()
        return group and format_menu_items(group) or format_root_menu_items()
    end)

    if not ok then
        vim.notify("Error formatting menu items: " .. tostring(items), vim.log.levels.ERROR)
        return
    end

    local title = group and group.name or "Which Key Menu"
    local placeholder = group and "Select an action or press <Esc> to cancel" or
                            "Select a group or action (groups shown with ▸)"

    local eval_ok, eval_err = pcall(vscode.eval, EVAL_STRINGS.quickpick_menu, {
        timeout = 1000,
        args = {
            items = items,
            title = title,
            placeholder = placeholder
        }
    })

    if not eval_ok then
        vim.notify("Error showing which-key menu: " .. tostring(eval_err), vim.log.levels.ERROR)
    end
end

local function hide_menu()
    pcall(vscode.eval, EVAL_STRINGS.hide_quickpick, {
        timeout = 1000
    })
end

local function handle_group(prefix, group)
    vim.keymap.set("n", prefix, function()
        show_menu(group)
    end, {
        noremap = true,
        silent = true
    })

    for _, binding in ipairs(group.bindings) do
        vim.keymap.set("n", prefix .. binding.key, function()
            hide_menu()
            pcall(vscode.action, binding.action)
        end, {
            noremap = true,
            silent = true,
            desc = binding.description
        })
    end
end

local function update_mode_display()
    local full_mode = vim.api.nvim_get_mode().mode
    local mode_key = full_mode:sub(1, 1)
    if mode_key == last_mode then
        return
    end

    local mode_data = MODE_DISPLAY[mode_key] or MODE_DISPLAY.n
    last_mode = mode_key
end

function M.setup()
    last_mode = ""

    vim.keymap.set("n", "<leader>", function()
        show_menu()
    end, {
        noremap = true,
        silent = true,
        desc = "Show which-key menu"
    })

    for prefix, group in pairs(keybindings) do
        handle_group("<leader>" .. prefix, group)
    end

    local menu_group = vim.api.nvim_create_augroup("WhichKeyMenu", {
        clear = true
    })
    local mode_group = vim.api.nvim_create_augroup("ModeDisplay", {
        clear = true
    })

    vim.api.nvim_create_autocmd({"ModeChanged", "CursorMoved"}, {
        callback = hide_menu,
        group = menu_group
    })

    vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*",
        callback = function()
            pcall(update_mode_display)
        end,
        group = mode_group
    })
end

return M
