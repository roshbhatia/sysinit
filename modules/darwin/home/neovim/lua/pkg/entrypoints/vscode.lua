local vscode = require('vscode')
local sysinit_lib = require('lib')

local function setup_keybindings()
    vim.keymap.set("n", "<C-h>", function()
        vscode.action("workbench.action.focusLeftGroup")
    end, {
        noremap = true,
        silent = true,
        desc = "Move to left window"
    })

    vim.keymap.set("n", "<C-j>", function()
        vscode.action("workbench.action.focusBelowGroup")
    end, {
        noremap = true,
        silent = true,
        desc = "Move to lower window"
    })

    vim.keymap.set("n", "<C-k>", function()
        vscode.action("workbench.action.focusAboveGroup")
    end, {
        noremap = true,
        silent = true,
        desc = "Move to upper window"
    })

    vim.keymap.set("n", "<C-l>", function()
        vscode.action("workbench.action.focusRightGroup")
    end, {
        noremap = true,
        silent = true,
        desc = "Move to right window"
    })

    vim.keymap.set("n", "<D-b>", function()
        vscode.action("workbench.view.explorer")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle explorer"
    })

    vim.keymap.set("n", "<A-b>", function()
        vscode.action("workbench.view.explorer")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle explorer"
    })

    vim.keymap.set("n", "<A-D-jkb>", function()
        vscode.action("workbench.action.chat.openInSidebar")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle chat"
    })

    for i = 1, 9 do
        vim.keymap.set("n", "<C-" .. i .. ">", function()
            vscode.action("workbench.action.openEditorAtIndex" .. i)
        end, {
            noremap = true,
            silent = true,
            desc = "Switch to editor " .. i
        })
    end

    vim.keymap.set({"n", "i"}, "<D-z>", function()
        vscode.action("undo")
    end, {
        noremap = true,
        silent = true,
        desc = "Undo"
    })

    vim.keymap.set({"n", "i"}, "<D-S-z>", function()
        vscode.action("redo")
    end, {
        noremap = true,
        silent = true,
        desc = "Redo"
    })

    vim.keymap.set({"n", "v", "i"}, "<D-a>", function()
        vscode.action("editor.action.selectAll")
    end, {
        noremap = true,
        silent = true,
        desc = "Select all"
    })

    vim.keymap.set({"n", "i"}, "<D-f>", function()
        vscode.action("actions.find")
    end, {
        noremap = true,
        silent = true,
        desc = "Find"
    })

    vim.keymap.set("n", "<D-S-f>", function()
        vscode.action("workbench.action.findInFiles")
    end, {
        noremap = true,
        silent = true,
        desc = "Find in files"
    })

    vim.keymap.set("n", "<D-p>", function()
        vscode.action("workbench.action.quickOpen")
    end, {
        noremap = true,
        silent = true,
        desc = "Quick open"
    })

    vim.keymap.set("n", "<D-S-p>", function()
        vscode.action("workbench.action.showCommands")
    end, {
        noremap = true,
        silent = true,
        desc = "Show commands"
    })
end

local function setup_plugins()
    local ui = {
        statusbar = require("pkg.plugins.ui.statusbar")
    }

    local keymaps = {
        commands = require("pkg.plugins.keymaps.commands"),
        pallete = require("pkg.plugins.keymaps.leader-pallete")
    }

    local modules = {ui.statusbar, keymaps.commands, keymaps.pallete}

    local specs = sysinit_lib.get_plugin_specs(modules)
    sysinit_lib.setup_package_manager(specs)
    sysinit_lib.setup_modules(modules)
end

local M = {}

function M.init()
    local config_path = vim.fn.stdpath('config')
    package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"
    sysinit_lib.setup_settings()

    vim.opt.foldmethod = "manual"
    vim.notify = require('vscode').notify
    vim.g.clipboard = vim.g.vscode_clipboard

    setup_plugins()
    setup_keybindings()
end

return M
