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
    local module_system = {
        vscode = {"which-key", "commands"}
    }

    local module_loader = require("common.module_loader")
    local specs = module_loader.get_plugin_specs(module_system)

    require('common.settings').setup_package_manager()
    module_loader.setup_modules(module_system)
end

local function is_valid_buffer(bufnr)
    return bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
end

local function init()
    local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
    vim.opt.rtp:prepend(init_dir)

    require('common.settings').setup_settings()

    -- Custom settings
    vim.opt.foldmethod = "manual"
    vim.notify = require('vscode').notify
    vim.g.clipboard = vim.g.vscode_clipboard

    setup_keybindings()
    setup_plugins()
    vim.cmd("Alpha")
end

init()
