local M = {}
local vscode = require('vscode')
local utils = require('config.utils')

local opts = { noremap = true, silent = true }

function M.setup()
    -- Basic navigation remains the same
    vim.keymap.set("n", "<C-h>", function() vscode.action("workbench.action.focusLeftGroup") end, opts)
    vim.keymap.set("n", "<C-j>", function() vscode.action("workbench.action.focusDownGroup") end, opts)
    vim.keymap.set("n", "<C-k>", function() vscode.action("workbench.action.focusUpGroup") end, opts)
    vim.keymap.set("n", "<C-l>", function() vscode.action("workbench.action.focusRightGroup") end, opts)

    -- Window splits (mirroring Neovim)
    vim.keymap.set('n', '<leader>\\', function() vscode.action('workbench.action.splitEditorRight') end, opts)
    vim.keymap.set('n', '<leader>-', function() vscode.action('workbench.action.splitEditorDown') end, opts)
    
    -- LSP-like functionality
    vim.keymap.set('n', 'gd', function() vscode.action('editor.action.revealDefinition') end, opts)
    vim.keymap.set('n', 'gr', function() vscode.action('editor.action.goToReferences') end, opts)
    vim.keymap.set('n', 'gi', function() vscode.action('editor.action.goToImplementation') end, opts)
    vim.keymap.set('n', 'K', function() vscode.action('editor.action.showHover') end, opts)

    -- Quick window operations
    vim.keymap.set('n', '<C-w>c', function() vscode.action('workbench.action.closeActiveEditor') end, opts)
    vim.keymap.set('n', '<C-w>o', function() vscode.action('workbench.action.closeOtherEditors') end, opts)
    vim.keymap.set('n', '<C-w>=', function() vscode.action('workbench.action.evenEditorWidths') end, opts)

    -- Window movement (similar to Neovim)
    vim.keymap.set('n', '<C-w>H', function() vscode.action('workbench.action.moveEditorToLeftGroup') end, opts)
    vim.keymap.set('n', '<C-w>J', function() vscode.action('workbench.action.moveEditorToBelowGroup') end, opts)
    vim.keymap.set('n', '<C-w>K', function() vscode.action('workbench.action.moveEditorToAboveGroup') end, opts)
    vim.keymap.set('n', '<C-w>L', function() vscode.action('workbench.action.moveEditorToRightGroup') end, opts)

    -- Buffer navigation
    vim.keymap.set('n', 'H', function() vscode.action('workbench.action.previousEditor') end, opts)
    vim.keymap.set('n', 'L', function() vscode.action('workbench.action.nextEditor') end, opts)

    -- Quick UI toggles (similar to your Neovim setup)
    vim.keymap.set('n', '<C-n>', function() vscode.action('workbench.action.toggleSidebarVisibility') end, opts)
    vim.keymap.set('n', '<C-\\>', function() vscode.action('workbench.action.terminal.toggleTerminal') end, opts)
    
    -- Line manipulation
    vim.keymap.set('n', '<A-j>', function() vscode.action('editor.action.moveLinesDownAction') end, opts)
    vim.keymap.set('n', '<A-k>', function() vscode.action('editor.action.moveLinesUpAction') end, opts)
    vim.keymap.set('v', '<A-j>', [[:m '>+1<CR>gv=gv]], opts)
    vim.keymap.set('v', '<A-k>', [[:m '<-2<CR>gv=gv]], opts)

    -- Keep cursor centered
    vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
    vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)
    vim.keymap.set('n', 'n', 'nzzzv', opts)
    vim.keymap.set('n', 'N', 'Nzzzv', opts)

    -- Quick escape from terminal
    vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], opts)
    
    -- Visual mode improvements
    vim.keymap.set('v', '<', '<gv', opts)
    vim.keymap.set('v', '>', '>gv', opts)
    vim.keymap.set('v', 'p', '"_dP', opts)

    -- Yank improvements
    vim.keymap.set({'n', 'v'}, '<leader>y', [["+y]], opts)
    vim.keymap.set('n', '<leader>Y', [["+Y]], opts)
    
    -- Quick inline chat access
    vim.keymap.set('n', '<leader>c]', function() vscode.action('inlineChat.start') end, opts)
    
    -- Quick save
    vim.keymap.set('n', '<leader>w', function() vscode.action('workbench.action.files.save') end, opts)
    
    -- Quick return to editor
    vim.keymap.set('n', '<Esc><Esc>', function() vscode.action('workbench.action.focusActiveEditorGroup') end, opts)

    -- Quick access commands
    vim.keymap.set({'n', 'i'}, '<D-p>', function() vscode.action('workbench.action.showCommands') end, opts)
    vim.keymap.set({'n', 'i'}, '<D-]>', function() vscode.action('inlineChat.start') end, opts)
    vim.keymap.set({'n', 'i'}, '<D-;>', function() vscode.action('extension.addDocComments') end, opts)
    vim.keymap.set({'n', 'i'}, '<D-S-\'>', function() vscode.action('codegpt.explainCodeGPT') end, opts)
    vim.keymap.set({'n', 'i'}, '<D-k><D-i>', function() vscode.action('editor.action.showHover') end, opts)
end

return M
