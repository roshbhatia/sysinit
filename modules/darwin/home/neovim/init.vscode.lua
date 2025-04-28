local vscode = require('vscode')
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
        ["vsc-statusbar"] = require("modules.ui.vsc-statusbar")
    }

    local editor = {
        oil = require("modules.editor.oil")
    }

    local tools = {
        ["vsc-commands"] = require("modules.tools.vsc-commands"),
        ["which-key"] = require("modules.tools.which-key")
    }

    local modules = {ui["vsc-statusbar"], editor.oil, tools["vsc-commands"], tools["which-key"]}

    local module_loader = require("common.module_loader")
    local specs = module_loader.get_plugin_specs(modules)
    require('common.settings').setup_package_manager(specs)
    module_loader.setup_modules(modules)
end

local function init()
    local config_path = vim.fn.stdpath('config')
    package.path = package.path .. ";" .. config_path .. "/?.lua" .. ";" .. config_path .. "/lua/?.lua"
    require('common.settings').setup_settings()

    -- Custom settings
    vim.opt.foldmethod = "manual"
    vim.notify = require('vscode').notify
    vim.g.clipboard = vim.g.vscode_clipboard

    setup_keybindings()
    setup_plugins()
end

init()
