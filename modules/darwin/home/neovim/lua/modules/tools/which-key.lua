local M = {}

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
            vscode_utils.show_menu(group, M.keybindings_vsc)
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

M.keybindings_data = {
    a = {
        name = "󱚤 AI",
        bindings = {{
            key = "c",
            desc = "Toggle Chat",
            neovim_cmd = "<cmd>CopilotChatToggle<CR>",
            vscode_cmd = "workbench.action.chat.openInSidebar"
        }, {
            key = "d",
            desc = "Generate Docs",
            neovim_cmd = "<cmd>CopilotChatDocumentThis<CR>",
            vscode_cmd = "github.copilot.chat.generateDocs"
        }, {
            key = "o",
            desc = "Optimize",
            neovim_cmd = "<cmd>CopilotChatOptimizeCode<CR>",
            vscode_cmd = "github.copilot.chat.fix"
        }, {
            key = "r",
            desc = "Refactor",
            neovim_cmd = "<cmd>CopilotChatRefactorCode<CR>",
            vscode_cmd = "github.copilot.chat.fix"
        }, {
            key = "f",
            desc = "Fix Code",
            neovim_cmd = "<cmd>CopilotChatFix<CR>",
            vscode_cmd = "github.copilot.chat.fix"
        }, {
            key = "e",
            desc = "Explain",
            neovim_cmd = "<cmd>CopilotChatExplain<CR>",
            vscode_cmd = "github.copilot.chat.explain"
        }, {
            key = "t",
            desc = "Generate Tests",
            neovim_cmd = "<cmd>CopilotChatTests<CR>",
            vscode_cmd = "github.copilot.chat.generateTests"
        }, {
            key = "i",
            desc = "Inline Chat",
            neovim_cmd = "<cmd>CopilotChatInline<CR>",
            vscode_cmd = "inlineChat.startWithCurrentLine"
        }, {
            key = "a",
            desc = "Accept Changes",
            neovim_cmd = "<cmd>CopilotChatAccept<CR>",
            vscode_cmd = "github.copilot.chat.review.apply"
        }, {
            key = "k",
            desc = "Discard Changes",
            neovim_cmd = "<cmd>CopilotChatDiscard<CR>",
            vscode_cmd = "github.copilot.chat.review.discard"
        }, {
            key = "g",
            desc = "Generate Commit",
            neovim_cmd = "<cmd>CopilotChatCommit<CR>",
            vscode_cmd = "github.copilot.git.generateCommitMessage"
        }}
    },
    b = {
        name = "󱅄 Buffer",
        bindings = {{
            key = "d",
            desc = "Close",
            neovim_cmd = "<cmd>BufferClose<CR>",
            vscode_cmd = "workbench.action.closeActiveEditor"
        }, {
            key = "n",
            desc = "Next",
            neovim_cmd = "<cmd>BufferNext<CR>",
            vscode_cmd = "workbench.action.nextEditor"
        }, {
            key = "o",
            desc = "Close Others",
            neovim_cmd = "<cmd>BufferCloseAllButCurrent<CR>",
            vscode_cmd = "workbench.action.closeOtherEditors"
        }, {
            key = "p",
            desc = "Previous",
            neovim_cmd = "<cmd>BufferPrevious<CR>",
            vscode_cmd = "workbench.action.previousEditor"
        }, {
            key = "t",
            desc = "Show in Tree",
            neovim_cmd = "Neotree toggle show buffers right<CR>",
            vscode_cmd = "git.revealInExplorer"
        }, {
            key = "i",
            desc = "New File",
            neovim_cmd = function()
                vim.ui.input({
                    prompt = "Enter file path: "
                }, function(input)
                    if input then
                        -- Create parent directories if they don't exist
                        local dir = vim.fn.fnamemodify(input, ":h")
                        if dir ~= "." and vim.fn.isdirectory(dir) == 0 then
                            vim.fn.mkdir(dir, "p")
                        end
                        vim.cmd("edit " .. input)
                    end
                end)
            end,
            vscode_cmd = "workbench.action.files.newUntitledFile"
        }}
    },
    c = {
        name = "󰘧 Code",
        bindings = {{
            key = "R",
            desc = "References",
            neovim_cmd = "<cmd>lua vim.lsp.buf.references()<CR>",
            vscode_cmd = "editor.action.goToReferences"
        }, {
            key = "a",
            desc = "Code Action",
            neovim_cmd = "<cmd>lua vim.lsp.buf.code_action()<CR>",
            vscode_cmd = "editor.action.quickFix"
        }, {
            key = "c",
            desc = "Toggle Comment",
            neovim_cmd = "<Plug>(comment_toggle_linewise_current)",
            vscode_cmd = "editor.action.commentLine"
        }, {
            key = "d",
            desc = "Definition",
            neovim_cmd = "<cmd>lua vim.lsp.buf.definition()<CR>",
            vscode_cmd = "editor.action.revealDefinition"
        }, {
            key = "f",
            desc = "Format",
            neovim_cmd = "<cmd>lua vim.lsp.buf.format()<CR>",
            vscode_cmd = "editor.action.formatDocument"
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
        }, {
            key = "r",
            desc = "Rename",
            neovim_cmd = "<cmd>lua vim.lsp.buf.rename()<CR>",
            vscode_cmd = "editor.action.rename"
        }}
    },
    f = {
        name = "󰀶 Find",
        bindings = {{
            key = "b",
            desc = "Buffers",
            neovim_cmd = "<cmd>Telescope buffers<CR>",
            vscode_cmd = "workbench.action.showAllEditors"
        }, {
            key = "f",
            desc = "Find Files",
            neovim_cmd = "<cmd>Telescope find_files<CR>",
            vscode_cmd = "search-preview.quickOpenWithPreview"
        }, {
            key = "g",
            desc = "Live Grep",
            neovim_cmd = "<cmd>Telescope live_grep<CR>",
            vscode_cmd = "workbench.action.findInFiles"
        }, {
            key = "r",
            desc = "Recent Files",
            neovim_cmd = "<cmd>Telescope oldfiles<CR>",
            vscode_cmd = "workbench.action.openRecent"
        }, {
            key = "s",
            desc = "Document Symbols",
            neovim_cmd = "<cmd>Telescope lsp_document_symbols<CR>",
            vscode_cmd = "workbench.action.showAllSymbols"
        }}
    },
    g = {
        name = "󰊢 Git",
        bindings = {{
            key = "D",
            desc = "Status",
            neovim_cmd = "<cmd>Telescope git_status<CR>",
            vscode_cmd = "workbench.view.scm"
        }, {
            key = "L",
            desc = "LazyGit",
            neovim_cmd = "<cmd>LazyGit<CR>",
            vscode_cmd = "workbench.view.scm"
        }, {
            key = "P",
            desc = "Pull",
            neovim_cmd = "<cmd>Git pull<CR>",
            vscode_cmd = "git.pull"
        }, {
            key = "S",
            desc = "Stage Buffer",
            neovim_cmd = "<cmd>Gitsigns stage_buffer<CR>",
            vscode_cmd = "git.stageAll"
        }, {
            key = "U",
            desc = "Reset Buffer Index",
            neovim_cmd = "<cmd>Gitsigns reset_buffer_index<CR>",
            vscode_cmd = "git.unstageAll"
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
            key = "d",
            desc = "Diff This",
            neovim_cmd = "<cmd>Gitsigns diffthis<CR>",
            vscode_cmd = "git.openChange"
        }, {
            key = "f",
            desc = "Fetch",
            neovim_cmd = "<cmd>Git fetch<CR>",
            vscode_cmd = "git.fetch"
        }, {
            key = "h",
            desc = "Select Hunk",
            neovim_cmd = "<cmd>Gitsigns select_hunk<CR>",
            vscode_cmd = "git.openChange"
        }, {
            key = "j",
            desc = "Next Hunk",
            neovim_cmd = "<cmd>Gitsigns next_hunk<CR>",
            vscode_cmd = "workbench.action.editor.nextChange"
        }, {
            key = "k",
            desc = "Previous Hunk",
            neovim_cmd = "<cmd>Gitsigns prev_hunk<CR>",
            vscode_cmd = "workbench.action.editor.previousChange"
        }, {
            key = "l",
            desc = "Reset Hunk",
            neovim_cmd = "<cmd>Gitsigns reset_hunk<CR>",
            vscode_cmd = "git.revertSelectedRanges"
        }, {
            key = "p",
            desc = "Push",
            neovim_cmd = "<cmd>Git push<CR>",
            vscode_cmd = "git.push"
        }, {
            key = "r",
            desc = "Reset Hunk",
            neovim_cmd = "<cmd>Gitsigns reset_hunk<CR>",
            vscode_cmd = "git.revertSelectedRanges"
        }, {
            key = "s",
            desc = "Stage Hunk",
            neovim_cmd = "<cmd>Gitsigns stage_hunk<CR>",
            vscode_cmd = "git.stage"
        }, {
            key = "u",
            desc = "Undo Stage Hunk",
            neovim_cmd = "<cmd>Gitsigns undo_stage_hunk<CR>",
            vscode_cmd = "git.unstage"
        }, {
            key = "v",
            desc = "Status (View)",
            neovim_cmd = "<cmd>Telescope git_status<CR>",
            vscode_cmd = "workbench.view.scm"
        }}
    },
    s = {
        name = "󰃻 Split",
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
        }}
    },
    t = {
        name = "󰨚 Toggle",
        bindings = {{
            key = "m",
            desc = "Commands",
            neovim_cmd = "<cmd>Telescope commands<CR>",
            vscode_cmd = "workbench.action.showCommands"
        }, {
            key = "o",
            desc = "Symbols Outline",
            neovim_cmd = "<cmd>SymbolsOutline<CR>",
            vscode_cmd = "outline.focus"
        }, {
            key = "e",
            desc = "Explorer",
            neovim_cmd = "<cmd>NvimTreeToggle<CR>",
            vscode_cmd = "workbench.view.explorer"
        }, {
            key = "t",
            desc = "Terminal",
            neovim_cmd = "<cmd>ToggleTerm<CR>",
            vscode_cmd = "workbench.action.terminal.toggleTerminal"
        }, {
            key = "p",
            desc = "Problems",
            neovim_cmd = "<cmd>TroubleToggle<CR>",
            vscode_cmd = "workbench.actions.view.problems"
        }}
    },
    w = {
        name = " Window",
        bindings = {{
            key = "=",
            desc = "Equal Size",
            neovim_cmd = "<C-w>=",
            vscode_cmd = "workbench.action.evenEditorWidths"
        }, {
            key = "H",
            desc = "Move Window Left",
            neovim_cmd = "<C-w>H",
            vscode_cmd = "workbench.action.moveEditorToLeftGroup"
        }, {
            key = "J",
            desc = "Move Window Down",
            neovim_cmd = "<C-w>J",
            vscode_cmd = "workbench.action.moveEditorToBelowGroup"
        }, {
            key = "K",
            desc = "Move Window Up",
            neovim_cmd = "<C-w>K",
            vscode_cmd = "workbench.action.moveEditorToAboveGroup"
        }, {
            key = "L",
            desc = "Move Window Right",
            neovim_cmd = "<C-w>L",
            vscode_cmd = "workbench.action.moveEditorToRightGroup"
        }, {
            key = "_",
            desc = "Max Height",
            neovim_cmd = "<C-w>_",
            vscode_cmd = "workbench.action.toggleEditorWidths"
        }, {
            key = "h",
            desc = "Focus Left Window",
            neovim_cmd = "<C-w>h",
            vscode_cmd = "workbench.action.focusLeftGroup"
        }, {
            key = "j",
            desc = "Focus Lower Window",
            neovim_cmd = "<C-w>j",
            vscode_cmd = "workbench.action.focusDownGroup"
        }, {
            key = "k",
            desc = "Focus Upper Window",
            neovim_cmd = "<C-w>k",
            vscode_cmd = "workbench.action.focusUpGroup"
        }, {
            key = "l",
            desc = "Focus Right Window",
            neovim_cmd = "<C-w>l",
            vscode_cmd = "workbench.action.focusRightGroup"
        }, {
            key = "o",
            desc = "Only Window",
            neovim_cmd = "<cmd>only<CR>",
            vscode_cmd = "workbench.action.closeOtherEditors"
        }, {
            key = "w",
            desc = "Close Window",
            neovim_cmd = "<cmd>close<CR>",
            vscode_cmd = "workbench.action.closeActiveEditor"
        }}
    }
}

-- Converts to v3 format
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

M.plugins = {{
    "folke/which-key.nvim",
    lazy = VeryLazy,
    config = function()
        if vim.g.vscode then
            M.keybindings_vsc = M.keybindings_data

            -- Setup VSCode <leader> key menu
            vim.keymap.set("n", "<leader>", function()
                vscode_utils.show_menu(nil, M.keybindings_vsc)
            end, {
                noremap = true,
                silent = true,
                desc = "Show which-key menu"
            })

            -- Setup VSCode group menus
            for prefix, group in pairs(M.keybindings_vsc) do
                vscode_utils.handle_group("<leader>" .. prefix, group)
            end

            -- Autocmd to hide menu on mode changes or cursor moved
            local menu_group = vim.api.nvim_create_augroup("WhichKeyMenu", {
                clear = true
            })

            vim.api.nvim_create_autocmd({"ModeChanged", "CursorMoved"}, {
                callback = vscode_utils.hide_menu,
                group = menu_group
            })
        else
            -- Regular Neovim which-key setup
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

            -- Convert unified format to which-key format
            local which_key_bindings = convert_to_which_key(M.keybindings_data)

            -- Add to which-key
            require("which-key").add(which_key_bindings)
        end
    end
}}

return M
