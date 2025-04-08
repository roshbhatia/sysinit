-- VSCode specific Neovim configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set timeout for keymaps to make which-key more responsive
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Configure cursor shapes for different modes
vim.opt.guicursor = "n-v-c:block-blinkon1,i-ci-ve:ver25-blinkon1,r-cr:hor20,o:hor50"

-- Initialize lazy if not already installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
    },
})

-- Only load VSCode-specific configurations when running inside VSCode
if vim.g.vscode then
    -- VSCode specific keybindings
    local vscode = require('vscode')

    -- Initialize which-key
    local ok, which_key = pcall(require, "which-key")
    if ok then
        which_key.setup({
            plugins = {
                marks = false,
                registers = false,
                spelling = { enabled = false },
                presets = {
                    operators = false,
                    motions = false,
                    text_objects = false,
                    windows = false,
                    nav = false,
                    z = false,
                    g = false,
                },
            },
            window = {
                border = "single",
                position = "bottom",
                margin = { 1, 0, 1, 0 },
                padding = { 2, 2, 2, 2 },
            },
            show_help = false,
            show_keys = false,
            triggers = "auto",
            triggers_nowait = {
                -- marks
                "'", "`", "g'", "g`",
                -- registers
                '"', "<c-r>",
                -- spelling
                "z=",
            },
            disable = { filetypes = { "TelescopePrompt" } },
        })

        -- Register mappings with which-key
        which_key.register({
            f = {
                name = "Find",
                f = { function() vscode.action('workbench.action.quickOpen') end, "Find File" },
                g = { function() vscode.action('workbench.action.findInFiles') end, "Find in Files" },
                b = { function() vscode.action('workbench.action.showAllEditors') end, "Show All Buffers" },
            },
            w = {
                name = "Window",
                c = { function() vscode.action('workbench.action.closeActiveEditor') end, "Close Window" },
                o = { function() vscode.action('workbench.action.closeOtherEditors') end, "Close Others" },
                ["|"] = { function() vscode.action('workbench.action.splitEditor') end, "Split Vertical" },
                ["-"] = { function() vscode.action('workbench.action.splitEditorDown') end, "Split Horizontal" },
            },
            c = {
                name = "Copilot",
                c = { function() vscode.action('github.copilot.interactiveEditor.toggle') end, "Toggle Copilot Chat" },
                a = { function() vscode.action('github.copilot.interactiveSession.setAgent') end, "Switch to Agent Mode" },
                e = { function() vscode.action('github.copilot.interactiveSession.editMode') end, "Switch to Edit Mode" },
                q = { function() vscode.action('github.copilot.interactiveSession.askMode') end, "Switch to Ask Mode" },
                f = { function() vscode.action('github.copilot.interactiveSession.fix') end, "Fix Issue" },
                x = { function() vscode.action('github.copilot.interactiveSession.explain') end, "Explain Code" },
                t = { function() vscode.action('github.copilot.interactiveSession.generateTests') end, "Generate Tests" },
            },
            h = {
                name = "Hunks/Git",
                s = { function() vscode.action('git.stage') end, "Stage" },
                u = { function() vscode.action('git.unstage') end, "Unstage" },
            },
            p = {
                name = "Project",
                n = { function() vscode.action('workbench.action.files.newUntitledFile') end, "New File" },
            },
            e = { function() vscode.action('workbench.action.toggleSidebarVisibility') end, "Toggle Explorer" },
            r = {
                name = "Refactor",
                n = { function() vscode.action('editor.action.rename') end, "Rename Symbol" },
            },
        }, { prefix = "<leader>", mode = "n" })

        -- Standard LSP bindings (these don't need which-key as they don't use leader)
        vim.keymap.set('n', 'gd', function() vscode.action('editor.action.revealDefinition') end)
        vim.keymap.set('n', 'gr', function() vscode.action('workbench.action.findReferences') end)
        vim.keymap.set('n', 'gi', function() vscode.action('editor.action.goToImplementation') end)
        vim.keymap.set('n', 'K', function() vscode.action('editor.action.showHover') end)

        -- Window navigation
        vim.keymap.set('n', '<C-h>', function() vscode.action('workbench.action.navigateLeft') end)
        vim.keymap.set('n', '<C-j>', function() vscode.action('workbench.action.navigateDown') end)
        vim.keymap.set('n', '<C-k>', function() vscode.action('workbench.action.navigateUp') end)
        vim.keymap.set('n', '<C-l>', function() vscode.action('workbench.action.navigateRight') end)

        -- Multi-cursor support
        vim.keymap.set('n', '<C-d>', function()
            vscode.with_insert(function()
                vscode.action("editor.action.addSelectionToNextFindMatch")
            end)
        end)

        -- Terminal integration
        vim.keymap.set('n', '<C-\\>', function() vscode.action('workbench.action.terminal.toggleTerminal') end)

        -- Copy command
        local function copy()
            if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then
                local backup = vim.fn.getreg('a')
                vim.cmd('normal! "ay')
                vscode.action('workbench.action.files.save')
                vim.fn.setreg('a', backup)
            end
        end
        vim.keymap.set('v', '<C-c>', copy)

        -- Configure which-key to show on first space press
        vim.keymap.set('n', '<Space>', function()
            vim.fn.feedkeys(' ', 'n')
        end, { silent = true })
    end
end