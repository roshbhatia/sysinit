local plugin_spec = {}

function plugin_spec.get_plugin_specs(modules)
    local specs = {}
    for _, module in ipairs(modules) do
        if module.plugins then
            for _, plugin in ipairs(module.plugins) do
                table.insert(specs, plugin)
            end
        end
    end
    return specs
end

function plugin_spec.setup_modules(modules)
    for _, module in ipairs(modules) do
        if module.setup then
            module.setup()
        end
    end
end

local vscode_utils = {}

if vim.g.vscode then
    vscode_utils.vscode = require('vscode')

    vscode_utils.EVAL_STRINGS = {
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
            const TIMEOUT_MS = 500;

            quickPick.onDidChangeValue((value) => {
              if (autoExecuteTimer) {
                clearTimeout(autoExecuteTimer);
              }

              const matchingItems = quickPick.items.filter(item =>
                item.label.toLowerCase().startsWith(value.toLowerCase())
              );

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

    vscode_utils.cache = {
        root_items = nil,
        group_items = {}
    }

    function vscode_utils.format_menu_items(group)
        local items = {}
        for _, binding in ipairs(group.bindings) do
            table.insert(items, {
                label = binding.key,
                description = binding.desc,
                action = binding.vscode_cmd,
                key = binding.key,
                isGroup = false,
                isGroupItem = false
            })
        end
        return items
    end

    function vscode_utils.format_root_menu_items(keybindings)
        if vscode_utils.cache.root_items then
            return vscode_utils.cache.root_items
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
                    description = binding.desc,
                    action = binding.vscode_cmd,
                    key = binding.key,
                    isGroup = false,
                    isGroupItem = true
                })
            end
            lastCategory = key
        end

        vscode_utils.cache.root_items = items
        return items
    end

    function vscode_utils.show_menu(group, keybindings)
        local ok, items = pcall(function()
            return group and vscode_utils.format_menu_items(group) or vscode_utils.format_root_menu_items(keybindings)
        end)

        if not ok then
            vim.notify("Error formatting menu items: " .. tostring(items), vim.log.levels.ERROR)
            return
        end

        local title = group and group.name or "Which Key Menu"
        local placeholder = group and "Select an action or press <Esc> to cancel" or
                                "Select a group or action (groups shown with ▸)"

        local eval_ok, eval_err = pcall(vscode_utils.vscode.eval, vscode_utils.EVAL_STRINGS.quickpick_menu, {
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

    function vscode_utils.hide_menu()
        pcall(vscode_utils.vscode.eval, vscode_utils.EVAL_STRINGS.hide_quickpick, {
            timeout = 1000
        })
    end

    function vscode_utils.handle_group(prefix, group)
        vim.keymap.set("n", prefix, function()
            vscode_utils.show_menu(group, M.keybindings_data)
        end, {
            noremap = true,
            silent = true
        })

        for _, binding in ipairs(group.bindings) do
            vim.keymap.set("n", prefix .. binding.key, function()
                vscode_utils.hide_menu()
                pcall(vscode_utils.vscode.action, binding.vscode_cmd)
            end, {
                noremap = true,
                silent = true,
                desc = binding.desc
            })
        end
    end
end

M.group_icons = {
    ai = "󱚤",
    buffer = "󱅄",
    code = "󰘧",
    debug = "",
    explorer = "󰒍",
    find = "󰀶",
    git = "󰊢",
    org = "",
    problems = "󰗯",
    split = "󰃻",
    tab = "",
    terminal = "",
    utils = "󰟻",
    window = ""
}

M.keybindings_data = {
    a = {
        name = M.group_icons.ai .. " AI",
        bindings = {{
            key = "a",
            desc = "Toggle Chat",
            neovim_cmd = "<cmd>AvanteToggle<CR>",
            vscode_cmd = "workbench.action.chat.toggle"
        }, {
            key = "n",
            desc = "New Chat",
            neovim_cmd = "<cmd>AvanteChatNew<CR>",
            vscode_cmd = "workbench.action.chat.newChat"
        }, {
            key = "c",
            desc = "Clear Chat",
            neovim_cmd = "<cmd>AvanteClear<CR>",
            vscode_cmd = "workbench.action.chat.clearHistory"
        }, {
            key = "e",
            desc = "Explain Code",
            neovim_cmd = "<cmd>CopilotChatExplain<CR>",
            vscode_cmd = "github.copilot.chat.explain"
        }, {
            key = "f",
            desc = "Fix Code",
            neovim_cmd = "<cmd>CopilotChatFix<CR>",
            vscode_cmd = "github.copilot.chat.fix"
        }, {
            key = "t",
            desc = "Generate Tests",
            neovim_cmd = "<cmd>CopilotChatTests<CR>",
            vscode_cmd = "github.copilot.chat.generateTests"
        }, {
            key = "d",
            desc = "Generate Docs",
            neovim_cmd = "<cmd>CopilotChatDocumentThis<CR>",
            vscode_cmd = "github.copilot.chat.generateDocs"
        }, {
            key = "r",
            desc = "Refactor Code",
            neovim_cmd = "<cmd>CopilotChatRefactorCode<CR>",
            vscode_cmd = "github.copilot.chat.fix"
        }, {
            key = "i",
            desc = "Inline Chat",
            neovim_cmd = "<cmd>CopilotChatInline<CR>",
            vscode_cmd = "inlineChat.start"
        }, {
            key = "g",
            desc = "Generate Commit",
            neovim_cmd = "<cmd>CopilotChatCommit<CR>",
            vscode_cmd = "github.copilot.git.generateCommitMessage"
        }}
    },

    b = {
        name = M.group_icons.buffer .. " Buffer",
        bindings = {{
            key = "b",
            desc = "Show Buffers",
            neovim_cmd = "<cmd>Telescope buffers<CR>",
            vscode_cmd = "workbench.action.showAllEditors"
        }, {
            key = "d",
            desc = "Close Buffer",
            neovim_cmd = "<cmd>bd<CR>",
            vscode_cmd = "workbench.action.closeActiveEditor"
        }, {
            key = "n",
            desc = "Next Buffer",
            neovim_cmd = "<cmd>bnext<CR>",
            vscode_cmd = "workbench.action.nextEditor"
        }, {
            key = "p",
            desc = "Previous Buffer",
            neovim_cmd = "<cmd>bprevious<CR>",
            vscode_cmd = "workbench.action.previousEditor"
        }, {
            key = "o",
            desc = "Close Other Buffers",
            neovim_cmd = "<cmd>%bd|e#|bd#<CR>",
            vscode_cmd = "workbench.action.closeOtherEditors"
        }, {
            key = "f",
            desc = "Find in Buffers",
            neovim_cmd = "<cmd>Telescope current_buffer_fuzzy_find<CR>",
            vscode_cmd = "actions.find"
        }}
    },

    c = {
        name = M.group_icons.code .. " Code",
        bindings = {{
            key = "c",
            desc = "Toggle Comment",
            neovim_cmd = "<Plug>(comment_toggle_linewise_current)",
            vscode_cmd = "editor.action.commentLine"
        }, {
            key = "a",
            desc = "Code Action",
            neovim_cmd = "<cmd>lua vim.lsp.buf.code_action()<CR>",
            vscode_cmd = "editor.action.quickFix"
        }, {
            key = "f",
            desc = "Format Document",
            neovim_cmd = "<cmd>lua vim.lsp.buf.format()<CR>",
            vscode_cmd = "editor.action.formatDocument"
        }, {
            key = "r",
            desc = "Rename Symbol",
            neovim_cmd = "<cmd>lua vim.lsp.buf.rename()<CR>",
            vscode_cmd = "editor.action.rename"
        }, {
            key = "h",
            desc = "Hover",
            neovim_cmd = "<cmd>lua vim.lsp.buf.hover()<CR>",
            vscode_cmd = "editor.action.showHover"
        }, {
            key = "d",
            desc = "Go to Definition",
            neovim_cmd = "<cmd>lua vim.lsp.buf.definition()<CR>",
            vscode_cmd = "editor.action.revealDefinition"
        }, {
            key = "i",
            desc = "Go to Implementation",
            neovim_cmd = "<cmd>lua vim.lsp.buf.implementation()<CR>",
            vscode_cmd = "editor.action.goToImplementation"
        }, {
            key = "R",
            desc = "Find References",
            neovim_cmd = "<cmd>lua vim.lsp.buf.references()<CR>",
            vscode_cmd = "editor.action.goToReferences"
        }, {
            key = "s",
            desc = "Document Symbols",
            neovim_cmd = "<cmd>Telescope lsp_document_symbols<CR>",
            vscode_cmd = "workbench.action.gotoSymbol"
        }}
    },

    d = {
        name = M.group_icons.debug .. " Debug",
        bindings = {{
            key = "d",
            desc = "Toggle Debugger",
            neovim_cmd = "<cmd>lua require'dap'.toggle_breakpoint()<CR>",
            vscode_cmd = "workbench.view.debug"
        }, {
            key = "b",
            desc = "Toggle Breakpoint",
            neovim_cmd = "<cmd>lua require'dap'.toggle_breakpoint()<CR>",
            vscode_cmd = "editor.debug.action.toggleBreakpoint"
        }, {
            key = "c",
            desc = "Continue",
            neovim_cmd = "<cmd>lua require'dap'.continue()<CR>",
            vscode_cmd = "workbench.action.debug.continue"
        }, {
            key = "s",
            desc = "Step Over",
            neovim_cmd = "<cmd>lua require'dap'.step_over()<CR>",
            vscode_cmd = "workbench.action.debug.stepOver"
        }, {
            key = "i",
            desc = "Step Into",
            neovim_cmd = "<cmd>lua require'dap'.step_into()<CR>",
            vscode_cmd = "workbench.action.debug.stepInto"
        }, {
            key = "o",
            desc = "Step Out",
            neovim_cmd = "<cmd>lua require'dap'.step_out()<CR>",
            vscode_cmd = "workbench.action.debug.stepOut"
        }, {
            key = "r",
            desc = "Restart",
            neovim_cmd = "<cmd>lua require'dap'.restart()<CR>",
            vscode_cmd = "workbench.action.debug.restart"
        }, {
            key = "t",
            desc = "Terminate",
            neovim_cmd = "<cmd>lua require'dap'.terminate()<CR>",
            vscode_cmd = "workbench.action.debug.stop"
        }}
    },

    e = {
        name = M.group_icons.explorer .. " Explorer",
        bindings = {{
            key = "e",
            desc = "Toggle Explorer",
            neovim_cmd = "<cmd>Neotree toggle<CR>",
            vscode_cmd = "workbench.action.toggleSidebarVisibility"
        }, {
            key = "f",
            desc = "Focus Explorer",
            neovim_cmd = "<cmd>Neotree focus<CR>",
            vscode_cmd = "workbench.view.explorer"
        }, {
            key = "r",
            desc = "Reveal in Explorer",
            neovim_cmd = "<cmd>Neotree reveal<CR>",
            vscode_cmd = "workbench.files.action.showActiveFileInExplorer"
        }, {
            key = "o",
            desc = "Open Oil",
            neovim_cmd = "<cmd>Oil --float<CR>",
            vscode_cmd = "workbench.explorer.fileView.focus"
        }}
    },

    f = {
        name = M.group_icons.find .. " Find",
        bindings = {{
            key = "f",
            desc = "Find Files",
            neovim_cmd = "<cmd>Telescope find_files<CR>",
            vscode_cmd = "workbench.action.quickOpen"
        }, {
            key = "g",
            desc = "Find in Files",
            neovim_cmd = "<cmd>Telescope live_grep<CR>",
            vscode_cmd = "workbench.action.findInFiles"
        }, {
            key = "b",
            desc = "Find in Buffers",
            neovim_cmd = "<cmd>Telescope buffers<CR>",
            vscode_cmd = "workbench.action.showAllEditors"
        }, {
            key = "s",
            desc = "Find Symbols",
            neovim_cmd = "<cmd>Telescope lsp_document_symbols<CR>",
            vscode_cmd = "workbench.action.gotoSymbol"
        }, {
            key = "w",
            desc = "Find Workspace Symbols",
            neovim_cmd = "<cmd>Telescope lsp_workspace_symbols<CR>",
            vscode_cmd = "workbench.action.showAllSymbols"
        }, {
            key = "r",
            desc = "Recent Files",
            neovim_cmd = "<cmd>Telescope oldfiles<CR>",
            vscode_cmd = "workbench.action.openRecent"
        }, {
            key = "c",
            desc = "Commands",
            neovim_cmd = "<cmd>Telescope commands<CR>",
            vscode_cmd = "workbench.action.showCommands"
        }, {
            key = "h",
            desc = "Help Tags",
            neovim_cmd = "<cmd>Telescope help_tags<CR>",
            vscode_cmd = "workbench.action.openDocumentationUrl"
        }}
    },

    g = {
        name = M.group_icons.git .. " Git",
        bindings = {{
            key = "g",
            desc = "View Status",
            neovim_cmd = "<cmd>Telescope git_status<CR>",
            vscode_cmd = "workbench.view.scm"
        }, {
            key = "b",
            desc = "Branches",
            neovim_cmd = "<cmd>Telescope git_branches<CR>",
            vscode_cmd = "git.checkout"
        }, {
            key = "c",
            desc = "Commit",
            neovim_cmd = "<cmd>Git commit<CR>",
            vscode_cmd = "git.commit"
        }, {
            key = "f",
            desc = "Fetch",
            neovim_cmd = "<cmd>Git fetch<CR>",
            vscode_cmd = "git.fetch"
        }, {
            key = "p",
            desc = "Pull",
            neovim_cmd = "<cmd>Git pull<CR>",
            vscode_cmd = "git.pull"
        }, {
            key = "P",
            desc = "Push",
            neovim_cmd = "<cmd>Git push<CR>",
            vscode_cmd = "git.push"
        }, {
            key = "j",
            desc = "Next Change",
            neovim_cmd = "<cmd>Gitsigns next_hunk<CR>",
            vscode_cmd = "workbench.action.editor.nextChange"
        }, {
            key = "k",
            desc = "Prev Change",
            neovim_cmd = "<cmd>Gitsigns prev_hunk<CR>",
            vscode_cmd = "workbench.action.editor.previousChange"
        }, {
            key = "d",
            desc = "Diff",
            neovim_cmd = "<cmd>Gitsigns diffthis<CR>",
            vscode_cmd = "git.openChange"
        }, {
            key = "s",
            desc = "Stage Hunk",
            neovim_cmd = "<cmd>Gitsigns stage_hunk<CR>",
            vscode_cmd = "git.stageSelectedRanges"
        }, {
            key = "u",
            desc = "Unstage Hunk",
            neovim_cmd = "<cmd>Gitsigns undo_stage_hunk<CR>",
            vscode_cmd = "git.unstageSelectedRanges"
        }, {
            key = "r",
            desc = "Reset Hunk",
            neovim_cmd = "<cmd>Gitsigns reset_hunk<CR>",
            vscode_cmd = "git.revertSelectedRanges"
        }, {
            key = "l",
            desc = "Git UI",
            neovim_cmd = "<cmd>Snacks.lazygit.open()<CR>",
            vscode_cmd = "git.openChange"
        }}
    },

    o = {
        name = M.group_icons.org .. " Organize",
        bindings = {{
            key = "o",
            desc = "Open Oil",
            neovim_cmd = "<cmd>Oil<CR>",
            vscode_cmd = "workbench.explorer.fileView.focus"
        }, {
            key = "t",
            desc = "Todo",
            neovim_cmd = "<cmd>TodoTelescope<CR>",
            vscode_cmd = "workbench.action.tasks.runTask"
        }, {
            key = "a",
            desc = "Auto-Session",
            neovim_cmd = "<cmd>SessionSave<CR>",
            vscode_cmd = "workbench.action.files.saveAll"
        }, {
            key = "s",
            desc = "Project Structure",
            neovim_cmd = "<cmd>Telescope file_browser<CR>",
            vscode_cmd = "workbench.files.action.showActiveFileInExplorer"
        }, {
            key = "p",
            desc = "Projects",
            neovim_cmd = "<cmd>Telescope projects<CR>",
            vscode_cmd = "workbench.action.openRecent"
        }}
    },

    p = {
        name = M.group_icons.problems .. " Problems",
        bindings = {{
            key = "p",
            desc = "Toggle Problems",
            neovim_cmd = "<cmd>Trouble toggle<CR>",
            vscode_cmd = "workbench.actions.view.toggleProblems"
        }, {
            key = "w",
            desc = "Workspace Diagnostics",
            neovim_cmd = "<cmd>Trouble workspace_diagnostics<CR>",
            vscode_cmd = "workbench.actions.view.problems"
        }, {
            key = "d",
            desc = "Document Diagnostics",
            neovim_cmd = "<cmd>Trouble document_diagnostics<CR>",
            vscode_cmd = "editor.action.marker.next"
        }, {
            key = "n",
            desc = "Next Problem",
            neovim_cmd = "<cmd>lua vim.diagnostic.goto_next()<CR>",
            vscode_cmd = "editor.action.marker.next"
        }, {
            key = "p",
            desc = "Previous Problem",
            neovim_cmd = "<cmd>lua vim.diagnostic.goto_prev()<CR>",
            vscode_cmd = "editor.action.marker.prev"
        }}
    },

    s = {
        name = M.group_icons.split .. " Split",
        bindings = {{
            key = "s",
            desc = "Horizontal Split",
            neovim_cmd = "<cmd>split<CR>",
            vscode_cmd = "workbench.action.splitEditorDown"
        }, {
            key = "v",
            desc = "Vertical Split",
            neovim_cmd = "<cmd>vsplit<CR>",
            vscode_cmd = "workbench.action.splitEditorRight"
        }, {
            key = "h",
            desc = "Focus Left",
            neovim_cmd = "<C-w>h",
            vscode_cmd = "workbench.action.focusLeftGroup"
        }, {
            key = "j",
            desc = "Focus Down",
            neovim_cmd = "<C-w>j",
            vscode_cmd = "workbench.action.focusBelowGroup"
        }, {
            key = "k",
            desc = "Focus Up",
            neovim_cmd = "<C-w>k",
            vscode_cmd = "workbench.action.focusAboveGroup"
        }, {
            key = "l",
            desc = "Focus Right",
            neovim_cmd = "<C-w>l",
            vscode_cmd = "workbench.action.focusRightGroup"
        }, {
            key = "c",
            desc = "Close Split",
            neovim_cmd = "<cmd>close<CR>",
            vscode_cmd = "workbench.action.closeActiveEditor"
        }, {
            key = "o",
            desc = "Only Split",
            neovim_cmd = "<cmd>only<CR>",
            vscode_cmd = "workbench.action.closeEditorsInOtherGroups"
        }}
    },

    t = {
        name = M.group_icons.tab .. " Tab",
        bindings = {{
            key = "t",
            desc = "Jump to Tab",
            neovim_cmd = "<cmd>Tabby jump_to_tab<CR>",
            vscode_cmd = "workbench.action.quickOpen"
        }, {
            key = "a",
            desc = "New Tab",
            neovim_cmd = "<cmd>$tabnew<CR>"
        }, {
            key = "c",
            desc = "Close Tab",
            neovim_cmd = "<cmd>tabclose<CR>"
        }, {
            key = "o",
            desc = "Close Other Tabs",
            neovim_cmd = "<cmd>tabonly<CR>"
        }, {
            key = "n",
            desc = "Next Tab",
            neovim_cmd = "<cmd>tabn<CR>"
        }, {
            key = "p",
            desc = "Previous Tab",
            neovim_cmd = "<cmd>tabp<CR>"
        }, {
            key = "mp",
            desc = "Move Tab Left",
            neovim_cmd = "<cmd>-tabmove<CR>"
        }, {
            key = "mn",
            desc = "Move Tab Right",
            neovim_cmd = "<cmd>+tabmove<CR>"
        }}
    },

    u = {
        name = M.group_icons.utils .. " Utils",
        bindings = {{
            key = "c",
            desc = "ColorPicker",
            neovim_cmd = "<cmd>PickColor<CR>",
            vscode_cmd = "editor.action.showColorPicker"
        }, {
            key = "h",
            desc = "Highlight",
            neovim_cmd = "<cmd>TSHighlightCapturesUnderCursor<CR>",
            vscode_cmd = "editor.action.selectHighlights"
        }, {
            key = "r",
            desc = "Restart LSP",
            neovim_cmd = "<cmd>LspRestart<CR>",
            vscode_cmd = "typescript.restartTsServer"
        }, {
            key = "m",
            desc = "Markdown Preview",
            neovim_cmd = "<cmd>MarkdownPreviewToggle<CR>",
            vscode_cmd = "markdown.showPreview"
        }, {
            key = "k",
            desc = "Keymaps",
            neovim_cmd = "<cmd>WhichKey<CR>",
            vscode_cmd = "workbench.action.openGlobalKeybindings"
        }}
    },

    w = {
        name = M.group_icons.window .. " Window",
        bindings = {{
            key = "w",
            desc = "Switch Window",
            neovim_cmd = "<C-w>w",
            vscode_cmd = "workbench.action.focusNextGroup"
        }, {
            key = "h",
            desc = "Left Window",
            neovim_cmd = "<C-w>h",
            vscode_cmd = "workbench.action.focusLeftGroup"
        }, {
            key = "j",
            desc = "Down Window",
            neovim_cmd = "<C-w>j",
            vscode_cmd = "workbench.action.navigateDown"
        }, {
            key = "k",
            desc = "Up Window",
            neovim_cmd = "<C-w>k",
            vscode_cmd = "workbench.action.navigateUp"
        }, {
            key = "l",
            desc = "Right Window",
            neovim_cmd = "<C-w>l",
            vscode_cmd = "workbench.action.focusRightGroup"
        }, {
            key = "c",
            desc = "Close Window",
            neovim_cmd = "<cmd>close<CR>",
            vscode_cmd = "workbench.action.closeActiveEditor"
        }, {
            key = "o",
            desc = "Close Others",
            neovim_cmd = "<cmd>only<CR>",
            vscode_cmd = "workbench.action.closeOtherEditors"
        }, {
            key = "=",
            desc = "Equal Width",
            neovim_cmd = "<C-w>=",
            vscode_cmd = "workbench.action.evenEditorWidths"
        }, {
            key = "v",
            desc = "Split Vertical",
            neovim_cmd = "<cmd>vsplit<CR>",
            vscode_cmd = "workbench.action.splitEditorRight"
        }, {
            key = "s",
            desc = "Split Horizontal",
            neovim_cmd = "<cmd>split<CR>",
            vscode_cmd = "workbench.action.splitEditorDown"
        }}
    }
}

local function convert_to_which_key(keybindings_data)
    local which_key_keybindings = {}

    for prefix, group in pairs(keybindings_data) do
        table.insert(which_key_keybindings, {
            "<leader>" .. prefix,
            group = group.name
        })

        for _, binding in ipairs(group.bindings) do
            table.insert(which_key_keybindings, {
                "<leader>" .. prefix .. binding.key,
                binding.neovim_cmd,
                desc = binding.desc
            })
        end
    end

    return which_key_keybindings
end

local function require_safe(module_name)
    local ok, module = pcall(require, module_name)
    if not ok then
        vim.notify("Failed to load module: " .. module_name, vim.log.levels.WARN)
        return nil
    end
    return module
end

M.plugins = {{
    "folke/which-key.nvim",
    lazy = false,
    config = function()
        if vim.g.vscode then
            M.keybindings_vsc = M.keybindings_data

            vim.keymap.set("n", "<leader>", function()
                vscode_utils.show_menu(nil, M.keybindings_vsc)
            end, {
                noremap = true,
                silent = true,
                desc = "Show which-key menu"
            })

            for prefix, group in pairs(M.keybindings_vsc) do
                vscode_utils.handle_group("<leader>" .. prefix, group)
            end

            local menu_group = vim.api.nvim_create_augroup("WhichKeyMenu", {
                clear = true
            })

            vim.api.nvim_create_autocmd({"ModeChanged", "CursorMoved"}, {
                callback = vscode_utils.hide_menu,
                group = menu_group
            })
        else
            require("which-key").setup({
                plugins = {
                    marks = true,
                    registers = true,
                    spelling = {
                        enabled = true,
                        suggestions = 20
                    },
                    presets = {
                        operators = true,
                        motions = true,
                        text_objects = true,
                        windows = true,
                        nav = true,
                        z = true,
                        g = true
                    }
                },
                win = {
                    border = "rounded",
                    padding = {2, 2, 2, 2}
                },
                layout = {
                    spacing = 3
                },
                icons = {
                    breadcrumb = "»",
                    separator = "➜",
                    group = "+"
                },
                show_help = true,
                show_keys = true,
                triggers = {{
                    "<auto>",
                    mode = "nxsotc"
                }}
            })

            local which_key_bindings = convert_to_which_key(M.keybindings_data)
            require("which-key").add(which_key_bindings)
        end
    end
}, {
    "mrjones2014/legendary.nvim",
    priority = 10000,
    lazy = false,
    dependencies = {"kkharji/sqlite.lua", "stevearc/dressing.nvim"},
    config = function()
        if not vim.g.vscode then
            local keybindings_data = M.keybindings_data
            local keymaps = {}
            for prefix, group in pairs(keybindings_data) do
                for _, binding in ipairs(group.bindings) do
                    table.insert(keymaps, {
                        "<leader>" .. prefix .. binding.key,
                        binding.neovim_cmd,
                        description = binding.desc,
                        group = group.name
                    })
                end
            end

            local legendary = require("legendary")
            legendary.setup({
                keymaps = keymaps,
                commands = {{
                    ":LegendaryPalette",
                    function()
                        legendary.find()
                    end,
                    description = "Open Command Palette"
                }},
                select_prompt = " Command Palette ",
                col_separator_char = "│",
                icons = {
                    keymap = "",
                    command = "",
                    fn = "󰡱",
                    itemgroup = ""
                },
                sort = {
                    most_recent_first = true,
                    user_items_first = true,
                    item_type_bias = nil,
                    frecency = {
                        db_root = string.format('%s/legendary/', vim.fn.stdpath('data')),
                        max_timestamps = 10
                    }
                },
                extensions = {
                    which_key = {
                        auto_register = true,
                        do_binding = false,
                        use_groups = true
                    },
                    lazy_nvim = true,
                    nvim_tree = false,
                    smart_splits = {
                        directions = {'h', 'j', 'k', 'l'},
                        mods = {
                            move = '<C>',
                            resize = '<M>'
                        }
                    },
                    diffview = true
                }
            })

            vim.keymap.set("n", "<leader>p", function()
                legendary.find()
            end, {
                desc = "Command Palette"
            })
        end
    end
}, {
    "stevearc/dressing.nvim",
    config = function()
        if not vim.g.vscode then
            require("dressing").setup({
                input = {
                    enabled = true,
                    default_prompt = "Input:",
                    title_pos = "left",
                    insert_only = true,
                    start_in_insert = true,
                    border = "rounded",
                    relative = "cursor",
                    prefer_width = 40,
                    width = nil,
                    max_width = {140, 0.9},
                    min_width = {20, 0.2},
                    win_options = {
                        winblend = 0,
                        wrap = false
                    }
                },
                select = {
                    enabled = true,
                    backend = {"telescope", "fzf", "builtin"},
                    trim_prompt = true,
                    telescope = {
                        layout_config = {
                            width = 0.65,
                            height = 0.7,
                            prompt_position = "top"
                        },
                        borderchars = {
                            prompt = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"},
                            results = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"},
                            preview = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"}
                        }
                    }
                }
            })
        end
    end
}, {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {"MunifTanjim/nui.nvim", "rcarriga/nvim-notify"},
    config = function()
        require("noice").setup({
            lsp = {
                -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true -- requires hrsh7th/nvim-cmp
                }
            },
            -- you can enable a preset for easier configuration
            presets = {
                bottom_search = false, -- use a classic bottom cmdline for search
                command_palette = false, -- position the cmdline and popupmenu together
                long_message_to_split = false, -- long messages will be sent to a split
                inc_rename = false, -- enables an input dialog for inc-rename.nvim
                lsp_doc_border = true -- add a border to hover docs and signature help
            }
        })
    end
}, {
    "smjonas/live-command.nvim",
    config = function()
        if not vim.g.vscode then
            require("live-command").setup({
                commands = {
                    Norm = {
                        cmd = "norm"
                    }
                }
            })
        end
    end
}}

return plugin_spec

