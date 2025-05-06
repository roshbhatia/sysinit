-- which-key/init.lua
-- A universal which-key implementation that automatically switches between
-- VSCode and Neovim implementations based on environment
local M = {}

-- Icons for different command categories
M.group_icons = {
    llm = "󱚤",
    buffer = "󱅄",
    code = "󰘧",
    debug = "󰘧",
    explorer = "󰒍",
    find = "󰀶",
    fold = "󰘧",
    git = "󰊢",
    lsp = "󰛖",
    notifications = "󰂚",
    org = "󰗯",
    problems = "󰗯",
    search = "󰍉",
    split = "󰃻",
    tab = "󱅄",
    terminal = "󱅄",
    utils = "󰟻",
    view = "󰛐",
    window = "󱅄"
}

-- Keybindings data structure - shared between VSCode and Neovim
M.keybindings_data = {
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
        }}
    },
    c = {
        name = M.group_icons.code .. " Code",
        bindings = {{
            key = "a",
            desc = "Code Actions",
            neovim_cmd = "<cmd>lua vim.lsp.buf.code_action()<CR>",
            vscode_cmd = "editor.action.sourceAction"
        }, {
            key = "c",
            desc = "Toggle Comment",
            neovim_cmd = "<Plug>(comment_toggle_linewise_current)",
            vscode_cmd = "editor.action.commentLine"
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
        }}
    },
    d = {
        name = M.group_icons.debug .. " Debug",
        bindings = {{
            key = "b",
            desc = "Toggle Breakpoint",
            neovim_cmd = "<cmd>lua require'dap'.toggle_breakpoint()<CR>",
            vscode_cmd = "editor.debug.action.toggleBreakpoint"
        }, {
            key = "c",
            desc = "Continue/Start",
            neovim_cmd = "<cmd>lua require'dap'.continue()<CR>",
            vscode_cmd = "workbench.action.debug.start"
        }, {
            key = "i",
            desc = "Step Into",
            neovim_cmd = "<cmd>lua require'dap'.step_into()<CR>",
            vscode_cmd = "workbench.action.debug.stepInto"
        }, {
            key = "o",
            desc = "Step Over",
            neovim_cmd = "<cmd>lua require'dap'.step_over()<CR>",
            vscode_cmd = "workbench.action.debug.stepOver"
        }, {
            key = "O",
            desc = "Step Out",
            neovim_cmd = "<cmd>lua require'dap'.step_out()<CR>",
            vscode_cmd = "workbench.action.debug.stepOut"
        }, {
            key = "t",
            desc = "Toggle DAP UI",
            neovim_cmd = "<cmd>lua require'dapui'.toggle()<CR>",
            vscode_cmd = "workbench.debug.action.toggleRepl"
        }}
    },
    e = {
        name = M.group_icons.explorer .. " Explorer",
        bindings = {{
            key = "e",
            desc = "Toggle Explorer",
            neovim_cmd = "<cmd>Neotree toggle<CR>",
            vscode_cmd = "workbench.view.explorer"
        }, {
            key = "o",
            desc = "Open Oil",
            neovim_cmd = "<cmd>Oil<CR>",
            vscode_cmd = "workbench.explorer.fileView.focus"
        }}
    },
    s = {
        name = M.group_icons.fold .. " Fold",
        bindings = {{
            key = "c",
            desc = "Close Fold",
            neovim_cmd = "zc",
            vscode_cmd = "editor.fold"
        }, {
            key = "o",
            desc = "Open Fold",
            neovim_cmd = "zo",
            vscode_cmd = "editor.unfold"
        }, {
            key = "t",
            desc = "Toggle Fold",
            neovim_cmd = "za",
            vscode_cmd = "editor.toggleFold"
        }, {
            key = "a",
            desc = "Toggle All Folds",
            neovim_cmd = "zA",
            vscode_cmd = "editor.toggleAllFolds"
        }}
    },
    g = {
        name = M.group_icons.git .. " Git",
        bindings = {{
            key = "g",
            desc = "LazyGit",
            neovim_cmd = "<cmd>LazyGit<CR>",
            vscode_cmd = "workbench.view.scm"
        }, {
            key = "b",
            desc = "Git Blame Toggle",
            neovim_cmd = "<cmd>BlamerToggle<CR>",
            vscode_cmd = "git.toggleBlame"
        }, {
            key = "p",
            desc = "Open PR",
            neovim_cmd = "<cmd>Octo pr list<CR>",
            vscode_cmd = "pr.openPullsWebsite"
        }, {
            key = "r",
            desc = "Review PR",
            neovim_cmd = "<cmd>Octo review start<CR>",
            vscode_cmd = "pr.openReview"
        }, {
            key = "c",
            desc = "Create PR",
            neovim_cmd = "<cmd>Octo pr create<CR>",
            vscode_cmd = "pr.create"
        }, {
            key = "d",
            desc = "View Diff",
            neovim_cmd = "<cmd>Octo pr diff<CR>",
            vscode_cmd = "pr.openDiffView"
        }, {
            key = "m",
            desc = "Merge PR",
            neovim_cmd = "<cmd>Octo pr merge<CR>",
            vscode_cmd = "pr.merge"
        }}
    },
    l = {
        name = M.group_icons.lsp .. " LSP",
        bindings = {{
            key = "d",
            desc = "Go to Definition",
            neovim_cmd = "<cmd>lua vim.lsp.buf.definition()<CR>",
            vscode_cmd = "editor.action.revealDefinition"
        }, {
            key = "r",
            desc = "Find References",
            neovim_cmd = "<cmd>lua vim.lsp.buf.references()<CR>",
            vscode_cmd = "editor.action.goToReferences"
        }, {
            key = "h",
            desc = "Hover",
            neovim_cmd = "<cmd>lua vim.lsp.buf.hover()<CR>",
            vscode_cmd = "editor.action.showHover"
        }, {
            key = "i",
            desc = "Implementation",
            neovim_cmd = "<cmd>lua vim.lsp.buf.implementation()<CR>",
            vscode_cmd = "editor.action.goToImplementation"
        }}
    },
    i = {
        name = M.group_icons.llm .. " LLM",
        bindings = {{
            key = "t",
            desc = "Toggle Chat",
            neovim_cmd = "<cmd>AvanteToggle<CR>",
            vscode_cmd = "workbench.action.chat.toggle"
        }, {
            key = "n",
            desc = "New Chat",
            neovim_cmd = "<cmd>CopilotChatOpen<CR>",
            vscode_cmd = "workbench.action.chat.newChat"
        }, {
            key = "s",
            desc = "Stop Chat",
            neovim_cmd = "<cmd>CopilotChatStop<CR>",
            vscode_cmd = "workbench.action.chat.stopListening"
        }, {
            key = "r",
            desc = "Reset Chat",
            neovim_cmd = "<cmd>CopilotChatReset<CR>",
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
            key = "d",
            desc = "Generate Docs",
            neovim_cmd = "<cmd>CopilotChatDocs<CR>",
            vscode_cmd = "github.copilot.chat.generateDocs"
        }, {
            key = "g",
            desc = "Generate Tests",
            neovim_cmd = "<cmd>CopilotChatTests<CR>",
            vscode_cmd = "github.copilot.chat.generateTests"
        }}
    },
    n = {
        name = M.group_icons.notifications .. " Notifications",
        bindings = {{
            key = "c",
            desc = "Clear All",
            neovim_cmd = "<cmd>NotificationsClear<CR>",
            vscode_cmd = "notifications.clearAll"
        }, {
            key = "t",
            desc = "Toggle",
            neovim_cmd = "<cmd>Notifications<CR>",
            vscode_cmd = "notifications.toggleList"
        }}
    },
    q = {
        name = M.group_icons.problems .. " Problems",
        bindings = {{
            key = "p",
            desc = "Show Problems",
            neovim_cmd = "<cmd>Telescope diagnostics<CR>",
            vscode_cmd = "workbench.actions.view.problems"
        }}
    },
    f = {
        name = M.group_icons.search .. " Search",
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
            key = "s",
            desc = "Find Symbol",
            neovim_cmd = "<cmd>Telescope lsp_document_symbols<CR>",
            vscode_cmd = "workbench.action.gotoSymbol"
        }}
    },
    p = {
        name = M.group_icons.split .. " Split",
        bindings = {{
            key = "v",
            desc = "Split Vertical",
            neovim_cmd = "<cmd>vsplit<CR>",
            vscode_cmd = "workbench.action.splitEditorRight"
        }, {
            key = "h",
            desc = "Split Horizontal",
            neovim_cmd = "<cmd>split<CR>",
            vscode_cmd = "workbench.action.splitEditorDown"
        }}
    },
    t = {
        name = M.group_icons.terminal .. " Terminal",
        bindings = {{
            key = "t",
            desc = "Toggle Terminal",
            neovim_cmd = "<cmd>ToggleTerm<CR>",
            vscode_cmd = "workbench.action.terminal.toggleTerminal"
        }}
    },
    v = {
        name = M.group_icons.view .. " View",
        bindings = {{
            key = "e",
            desc = "Toggle Explorer",
            neovim_cmd = "<cmd>NvimTreeToggle<CR>",
            vscode_cmd = "workbench.action.toggleSidebarVisibility"
        }, {
            key = "p",
            desc = "Toggle Panel",
            neovim_cmd = "<cmd>lua require('toggleterm').toggle()<CR>",
            vscode_cmd = "workbench.action.togglePanel"
        }}
    },
    w = {
        name = M.group_icons.window .. " Window",
        bindings = {{
            key = "w",
            desc = "Save",
            neovim_cmd = "<cmd>w<CR>",
            vscode_cmd = "workbench.action.files.save"
        }, {
            key = "q",
            desc = "Close Window",
            neovim_cmd = "<cmd>q<CR>",
            vscode_cmd = "workbench.action.closeWindow"
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
