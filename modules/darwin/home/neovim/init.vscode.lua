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
    local tools = {
        ["vsc-commands"] = require("modules.tools.vsc-commands"),
        ["vsc-which-key"] = require("modules.tools.vsc-which-key")
    }

    local modules = {tools["vsc-commands"], tools["vsc-which-key"]}

    local module_loader = require("common.module_loader")
    local specs = module_loader.get_plugin_specs(modules)
    require('common.settings').setup_package_manager(specs)
    module_loader.setup_modules(modules)
end

local function init()
    local current_dir = debug.getinfo(1).source:match("@?(.*/)") or "./"
    package.path = package.path .. ";" .. current_dir .. "?.lua" .. ";" .. current_dir .. "lua/?.lua"

    require('common.settings').setup_settings()

    -- Custom settings
    vim.opt.foldmethod = "manual"
    vim.notify = require('vscode').notify
    vim.g.clipboard = vim.g.vscode_clipboard

    setup_keybindings()
    setup_plugins()
end

init()
