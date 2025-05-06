-- which-key/init.lua
-- A universal which-key implementation that automatically switches between
-- VSCode and Neovim implementations based on environment
local M = {}

-- Icons for different command categories
M.group_icons = {
    ai = "󱚤", -- AI-related commands
    buffer = "󱅄", -- Buffer management
    code = "󰘧", -- Code actions and navigation
    debug = "", -- Debugging utilities
    explorer = "󰒍", -- File explorer
    find = "󰀶", -- Search and find tools
    git = "󰊢", -- Git operations
    org = "", -- Organization tools
    problems = "󰗯", -- Diagnostics and problems
    split = "󰃻", -- Window splitting
    tab = "", -- Tab management
    terminal = "", -- Terminal operations
    utils = "󰟻", -- Utilities
    window = "" -- Window management
}

-- Keybindings data structure - shared between VSCode and Neovim
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
            neovim_cmd = "<cmd>LazyGit<CR>",
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

-- Define plugins spec for lazy.nvim
M.plugins = {}

if vim.g.vscode then
    -- VSCode Implementation
    table.insert(M.plugins, {
        dir = ".", -- This is a virtual plugin - no actual files needed
        name = "vscode-which-key",
        event = "VeryLazy",
        cond = vim.g.vscode,
        config = function()
            local vscode = require("vscode")

            -- Cache for menu items
            local cache = {
                root_items = nil,
                group_items = {}
            }

            -- Evaluation strings for VSCode integration
            local EVAL_STRINGS = {
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

            -- Format menu items for a group
            local function format_menu_items(group)
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

            -- Format root menu items
            local function format_root_menu_items(keybindings)
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
                            description = binding.desc,
                            action = binding.vscode_cmd,
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

            -- Show the menu
            local function show_menu(group, keybindings)
                local ok, items = pcall(function()
                    return group and format_menu_items(group) or format_root_menu_items(keybindings)
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

            -- Hide the menu
            local function hide_menu()
                pcall(vscode.eval, EVAL_STRINGS.hide_quickpick, {
                    timeout = 1000
                })
            end

            -- Handle a group of keybindings
            local function handle_group(prefix, group)
                vim.keymap.set("n", prefix, function()
                    show_menu(group, M.keybindings_data)
                end, {
                    noremap = true,
                    silent = true
                })

                for _, binding in ipairs(group.bindings) do
                    if binding.vscode_cmd then
                        vim.keymap.set("n", prefix .. binding.key, function()
                            hide_menu()
                            pcall(vscode.action, binding.vscode_cmd)
                        end, {
                            noremap = true,
                            silent = true,
                            desc = binding.desc
                        })
                    end
                end
            end

            -- Set up the main leader mapping
            vim.keymap.set("n", "<leader>", function()
                show_menu(nil, M.keybindings_data)
            end, {
                noremap = true,
                silent = true,
                desc = "Show which-key menu"
            })

            -- Set up all the group keybindings
            for prefix, group in pairs(M.keybindings_data) do
                handle_group("<leader>" .. prefix, group)
            end

            -- Create autocmds to hide the menu when appropriate
            local menu_group = vim.api.nvim_create_augroup("WhichKeyMenu", {
                clear = true
            })

            vim.api.nvim_create_autocmd({"ModeChanged", "CursorMoved"}, {
                callback = hide_menu,
                group = menu_group
            })
        end
    })
else
    -- Neovim Implementation using wf.nvim
    table.insert(M.plugins, {
        "Cassin01/wf.nvim",
        event = "VeryLazy",
        config = function()
            local which_key = require("wf.builtin.which_key")

            -- Initialize wf.nvim
            require("wf").setup({
                theme = "default",
                behavior = {
                    skip_front_duplication = true,
                    skip_back_duplication = true
                }
            })

            -- Create the mappings object for wf.nvim
            local mappings = {}

            -- Set up the mappings for wf.nvim
            for prefix, group in pairs(M.keybindings_data) do
                -- Set keymaps manually in the Neovim way
                for _, binding in ipairs(group.bindings) do
                    if binding.neovim_cmd then
                        vim.keymap.set("n", "<leader>" .. prefix .. binding.key, binding.neovim_cmd, {
                            noremap = true,
                            silent = true,
                            desc = group.name .. ": " .. binding.desc
                        })
                    end
                end
            end

            -- Build the key groups dictionary for wf.nvim
            local key_group_dict = {}
            for prefix, group in pairs(M.keybindings_data) do
                key_group_dict["<leader>" .. prefix] = group.name
            end

            -- Set up the which-key mapping with wf.nvim
            vim.keymap.set("n", "<leader>", which_key({
                text_insert_in_advance = "<leader>",
                key_group_dict = key_group_dict,
                behavior = {
                    skip_front_duplication = true,
                    skip_back_duplication = true
                },
                title = "Commands"
            }))

            -- Register additional wf.nvim pickers
            M.register = require("wf.builtin.register")
            M.bookmark = require("wf.builtin.bookmark")
            M.buffer = require("wf.builtin.buffer")
            M.mark = require("wf.builtin.mark")
        end
    })
end

return M
