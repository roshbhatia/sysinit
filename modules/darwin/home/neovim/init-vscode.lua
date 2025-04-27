local function setup_neovim_settings()
    vim.opt.number = true
    vim.opt.cursorline = true
    vim.opt.signcolumn = "yes"
    vim.opt.termguicolors = true
    vim.opt.showmode = false
    vim.opt.lazyredraw = true

    vim.opt.foldmethod = "manual"
    vim.opt.foldenable = false
    vim.opt.foldlevel = 99
end

local function setup_vscode_integration()
    vim.cmd("set eventignore+=VimEnter")
    vim.notify("VSCode Neovim integration detected", vim.log.levels.INFO)
end

local function setup_keybindings()
    local opts = {
        noremap = true,
        silent = true
    }

    vim.keymap.set("n", "<C-h>", function()
        vscode.action("workbench.action.focusLeftGroup")
    end, opts)
    vim.keymap.set("n", "<C-j>", function()
        vscode.action("workbench.action.focusDownGroup")
    end, opts)
    vim.keymap.set("n", "<C-k>", function()
        vscode.action("workbench.action.focusUpGroup")
    end, opts)
    vim.keymap.set("n", "<C-l>", function()
        vscode.action("workbench.action.focusRightGroup")
    end, opts)

    vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
    vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
    vim.keymap.set("n", "n", "nzzzv", opts)
    vim.keymap.set("n", "N", "Nzzzv", opts)

    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], opts)
end

local function setup_plugins()
    local module_system = {
        vscode = {"which-key", "commands"}
    }

    local module_loader = require("core.module_loader")
    local specs = module_loader.get_plugin_specs(module_system)

    module_loader.setup_modules(module_system)
end

local function is_valid_buffer(bufnr)
    return bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
end

local function init()
    local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
    local lua_dir = init_dir .. "/lua"
    vim.opt.rtp:prepend(lua_dir)

    local common = require('common')
    common.setup_settings()

    setup_neovim_settings()
    setup_vscode_integration()

    vim.api.nvim_create_autocmd("UIEnter", {
        once = true,
        callback = function()
            setup_keybindings()
            setup_plugins()
        end
    })
end

init()
