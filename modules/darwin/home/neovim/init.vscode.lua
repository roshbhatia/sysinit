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
        ["vsc-statusbar"] = require("plugins.configs.ui.vsc-statusbar")
    }

    local tools = {
        ["vsc-commands"] = require("plugins.configs.tools.vsc-commands"),
        ["which-key"] = require("plugins.configs.tools.which-key")
    }

    local modules = {ui["vsc-statusbar"], tools["vsc-commands"], tools["which-key"]}
    sysinit_lib.setup_modules(modules)
end

local function init()
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

init()
