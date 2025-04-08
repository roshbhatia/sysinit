-- VSCode specific Neovim configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set timeout for keymaps
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Enable system clipboard integration
vim.opt.clipboard:append("unnamedplus")

if vim.g.vscode then
    local vscode = require('vscode')

    -- Configure WhichKey bindings
    local whichkey_bindings = {
        bindings = {
            {
                key = "f",
                name = "󰈔 File...",
                type = "bindings",
                bindings = {
                    {
                        key = "f",
                        name = "󰈞 Find File",
                        type = "command",
                        command = "workbench.action.quickOpen"
                    },
                    {
                        key = "s",
                        name = "󰏘 Save",
                        type = "command",
                        command = "workbench.action.files.save"
                    },
                    {
                        key = "S",
                        name = "󰏗 Save All",
                        type = "command",
                        command = "workbench.action.files.saveAll"
                    },
                    {
                        key = "r",
                        name = "󰈢 Recent Files",
                        type = "command",
                        command = "workbench.action.openRecent"
                    },
                    {
                        key = "n",
                        name = "󰎔 New File",
                        type = "command",
                        command = "workbench.action.files.newUntitledFile"
                    }
                }
            },
            {
                key = "e",
                name = "󰙅 Explorer",
                type = "command",
                command = "workbench.view.explorer"
            },
            {
                key = "s",
                name = "󰛔 Search...",
                type = "bindings",
                bindings = {
                    {
                        key = "f",
                        name = "󰍉 Find in Files",
                        type = "command",
                        command = "workbench.action.findInFiles"
                    },
                    {
                        key = "s",
                        name = "󰱽 Search Symbol",
                        type = "command",
                        command = "workbench.action.showAllSymbols"
                    }
                }
            },
            {
                key = "g",
                name = "󰊢 Git...",
                type = "bindings",
                bindings = {
                    {
                        key = "s",
                        name = "󰊢 Source Control",
                        type = "command",
                        command = "workbench.view.scm"
                    },
                    {
                        key = "b",
                        name = "󰘬 Branches",
                        type = "command",
                        command = "git.branchList"
                    },
                    {
                        key = "c",
                        name = "󰜘 Commit",
                        type = "command",
                        command = "git.commit"
                    }
                }
            },
            {
                key = "w",
                name = "󱂬 Window...",
                type = "bindings",
                bindings = {
                    {
                        key = "v",
                        name = "󰤱 Split Vertical",
                        type = "command",
                        command = "workbench.action.splitEditor"
                    },
                    {
                        key = "h",
                        name = "󰤲 Split Horizontal",
                        type = "command",
                        command = "workbench.action.splitEditorOrthogonal"
                    },
                    {
                        key = "w",
                        name = "󰖭 Close Editor",
                        type = "command",
                        command = "workbench.action.closeActiveEditor"
                    }
                }
            },
            {
                key = "c",
                name = "󰅩 Code...",
                type = "bindings",
                bindings = {
                    {
                        key = "a",
                        name = "󰏢 Actions",
                        type = "command",
                        command = "editor.action.quickFix"
                    },
                    {
                        key = "r",
                        name = "󰑕 Rename",
                        type = "command",
                        command = "editor.action.rename"
                    },
                    {
                        key = "f",
                        name = "󰉨 Format",
                        type = "command",
                        command = "editor.action.formatDocument"
                    }
                }
            }
        }
    }

    -- Configure VSCode settings for WhichKey
    vscode.update_config("whichkey.bindings", whichkey_bindings.bindings)

    -- Set up the space key to trigger WhichKey in normal and visual modes
    local vim_settings = {
        normalModeKeyBindingsNonRecursive = {
            {
                before = {"<space>"},
                commands = {"whichkey.show"}
            }
        },
        visualModeKeyBindingsNonRecursive = {
            {
                before = {"<space>"},
                commands = {"whichkey.show"}
            }
        }
    }

    -- Update VSCode Vim settings
    vscode.update_config("vim.normalModeKeyBindingsNonRecursive", vim_settings.normalModeKeyBindingsNonRecursive)
    vscode.update_config("vim.visualModeKeyBindingsNonRecursive", vim_settings.visualModeKeyBindingsNonRecursive)

    -- Map space in normal and visual modes to trigger WhichKey
    vim.keymap.set("n", "<Space>", function()
        vscode.action("whichkey.show")
    end, { silent = true })
    
    vim.keymap.set("v", "<Space>", function()
        vscode.action("whichkey.show")
    end, { silent = true })
end

-- Configure enhanced cursor appearance for different modes
vim.opt.guicursor = table.concat({
    "n-c:block-blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
    "i-ci-ve:ver25-blinkwait400-blinkoff250-blinkon500-CursorIM/lCursor",
    "v-sm:block-blinkwait175-blinkoff150-blinkon175-Visual/lCursor",
    "r-cr-o:hor20-blinkwait700-blinkoff400-blinkon250-CursorRM/lCursor"
}, ",")

-- Create highlight groups for different cursor modes
vim.api.nvim_create_autocmd({"ColorScheme", "VimEnter"}, {
    callback = function()
        -- Normal mode cursor (orange)
        vim.api.nvim_set_hl(0, "Cursor", { fg = "#282828", bg = "#fe8019" })
        -- Insert mode cursor (bright green)
        vim.api.nvim_set_hl(0, "CursorIM", { fg = "#282828", bg = "#b8bb26" })
        -- Visual mode cursor (purple)
        vim.api.nvim_set_hl(0, "Visual", { fg = "#282828", bg = "#d3869b" })
        -- Replace mode cursor (red)
        vim.api.nvim_set_hl(0, "CursorRM", { fg = "#282828", bg = "#fb4934" })
    end
})