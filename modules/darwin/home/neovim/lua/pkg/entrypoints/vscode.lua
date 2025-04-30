local vscode = require('vscode')
local sysinit_lib = require('lib')

local function setup_keybindings()
    -- ctrl + hjkl for moving between panes
    vim.keymap.set("n", "<C-h>", function()
        vscode.action("workbench.action.focusLeftGroup")
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set("n", "<C-j>", function()
        vscode.action("workbench.action.focusDownGroup")
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set("n", "<C-k>", function()
        vscode.action("workbench.action.focusUpGroup")
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set("n", "<C-l>", function()
        vscode.action("workbench.action.focusRightGroup")
    end, {
        noremap = true,
        silent = true
    })
end

local function setup_plugins()
    local ui = {
        statusbar = require("pkg.plugins.ui.statusbar")
    }

    local keymaps = {
        commands = require("pkg.plugins.keymaps.commands")
    }

    local modules = {ui.statusbar, keymaps.commands}

    local specs = sysinit_lib.get_plugin_specs(modules)
    sysinit_lib.setup_package_manager(specs)
    sysinit_lib.setup_modules(modules)
end

local M = {}

function M.init()
    local config_path = vim.fn.stdpath('config')
    package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"
    sysinit_lib.setup_settings()

    -- Custom settings
    vim.opt.foldmethod = "manual"
    vim.notify = require('vscode').notify
    vim.g.clipboard = vim.g.vscode_clipboard

    setup_plugins()
    setup_keybindings()
end

return M
