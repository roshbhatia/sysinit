-- keymaps/init.lua
-- Main keymaps loader that loads and aggregates all keymap groups
local M = {}

-- Group icons for different command categories
M.group_icons = {
    buffer = "󱅄",     -- Buffer operations
    code = "󰘧",       -- Code actions
    debug = "󰘧",      -- Debugging 
    explorer = "󰒍",   -- File explorer
    find = "󰀶",       -- Find/search operations
    fold = "󰘧",       -- Code folding
    git = "󰊢",        -- Git operations
    lsp = "󰛖",        -- LSP features
    llm = "󱚤",        -- LLM/AI assistants
    notifications = "󰂚", -- Notifications
    problems = "󰗯",   -- Problem/diagnostics
    search = "󰍉",     -- Search features
    split = "󰃻",      -- Window splitting
    tab = "󱅄",        -- Tab operations
    terminal = "󱅄",   -- Terminal operations
    utils = "󰟻",      -- Utilities
    view = "󰛐",       -- View operations
    window = "󱅄"      -- Window operations
}

-- Store for all keybindings loaded from modules
M.keybindings_data = {}

-- Register a keymap group from a module
function M.register_group(key, name, bindings)
    if not M.keybindings_data[key] then
        M.keybindings_data[key] = {
            name = name,
            bindings = {}
        }
    end

    -- Add or update bindings in the group
    for _, binding in ipairs(bindings) do
        table.insert(M.keybindings_data[key].bindings, binding)
    end
end

-- Load all keymap group modules
function M.load_groups()
    local group_path = "sysinit.plugins.keymaps.groups."
    local groups = {
        "buffer",
        "code",
        "debug",
        "explorer",
        "fold",
        "git",
        "lsp",
        "llm",
        "notifications",
        "problems",
        "search",
        "split",
        "terminal",
        "view",
        "window"
    }

    for _, group in ipairs(groups) do
        local ok, module = pcall(require, group_path .. group)
        if ok and module then
            if type(module.setup) == "function" then
                module.setup()
            end
        end
    end
    
    return M.keybindings_data
end

-- Define plugins spec for lazy.nvim
M.plugins = {}

-- Add which-key plugin (either VSCode or Neovim implementation based on environment)
if vim.g.vscode then
    -- VSCode Implementation
    table.insert(M.plugins, {
        dir = ".", -- This is a virtual plugin - no actual files needed
        name = "vscode-which-key",
        event = "VeryLazy",
        cond = vim.g.vscode,
        config = function()
            local vscode = require("vscode")
            
            -- Load all keybinding groups
            local keybindings = M.load_groups()

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
                    show_menu(group, keybindings)
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
                show_menu(nil, keybindings)
            end, {
                noremap = true,
                silent = true,
                desc = "Show which-key menu"
            })

            -- Set up all the group keybindings
            for prefix, group in pairs(keybindings) do
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
            
            -- Load all keybinding groups
            local keybindings = M.load_groups()

            -- Initialize wf.nvim
            require("wf").setup({
                theme = "default",
                behavior = {
                    skip_front_duplication = true,
                    skip_back_duplication = true
                }
            })

            -- Set up the mappings for wf.nvim
            for prefix, group in pairs(keybindings) do
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
            for prefix, group in pairs(keybindings) do
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