local M = {}
local vscode = require('vscode')
local utils = require('config.utils')

local opts = { noremap = true, silent = true }

-- Initialize all mappings
function M.setup()
    -- Basic navigation
    vim.keymap.set("n", "<C-h>", function() vscode.action("workbench.action.navigateLeft") end, opts)
    vim.keymap.set("n", "<C-j>", function() vscode.action("workbench.action.navigateDown") end, opts)
    vim.keymap.set("n", "<C-k>", function() vscode.action("workbench.action.navigateUp") end, opts)
    vim.keymap.set("n", "<C-l>", function() vscode.action("workbench.action.navigateRight") end, opts)

    -- Window management
    vim.keymap.set('n', '<leader>\\', function() vscode.action('workbench.action.splitEditorRight') end, opts)
    vim.keymap.set('n', '<leader>-', function() vscode.action('workbench.action.splitEditorDown') end, opts)
    
    -- Window resizing
    vim.keymap.set('n', '<C-Up>', function() vscode.action('workbench.action.increaseViewHeight') end, opts)
    vim.keymap.set('n', '<C-Down>', function() vscode.action('workbench.action.decreaseViewHeight') end, opts)
    vim.keymap.set('n', '<C-Left>', function() vscode.action('workbench.action.decreaseViewWidth') end, opts)
    vim.keymap.set('n', '<C-Right>', function() vscode.action('workbench.action.increaseViewWidth') end, opts)

    -- LSP-like functionality
    vim.keymap.set('n', 'gd', function() vscode.action('editor.action.revealDefinition') end, opts)
    vim.keymap.set('n', 'gr', function() vscode.action('editor.action.goToReferences') end, opts)
    vim.keymap.set('n', 'gi', function() vscode.action('editor.action.goToImplementation') end, opts)
    vim.keymap.set('n', 'K', function() vscode.action('editor.action.showHover') end, opts)

    -- Diagnostic navigation
    vim.keymap.set('n', '[d', function() vscode.action('editor.action.marker.prev') end, opts)
    vim.keymap.set('n', ']d', function() vscode.action('editor.action.marker.next') end, opts)
    vim.keymap.set('n', '[q', function() vscode.action('editor.action.marker.prev') end, opts)
    vim.keymap.set('n', ']q', function() vscode.action('editor.action.marker.next') end, opts)

    -- Buffer operations
    vim.keymap.set('n', 'H', function() vscode.action('workbench.action.previousEditor') end, opts)
    vim.keymap.set('n', 'L', function() vscode.action('workbench.action.nextEditor') end, opts)

    -- Terminal integration
    vim.keymap.set('n', '<C-\\>', function() vscode.action('workbench.action.terminal.toggleTerminal') end, opts)
    vim.keymap.set('n', '<leader>tf', function() vscode.action('workbench.action.terminal.focus') end, opts)
    vim.keymap.set('n', '<leader>tn', function() vscode.action('workbench.action.terminal.new') end, opts)

    -- File operations
    vim.keymap.set('n', '<leader>w', function() vscode.action('workbench.action.files.save') end, opts)
    vim.keymap.set('n', '<C-s>', function() vscode.action('workbench.action.files.save') end, opts)
    vim.keymap.set('i', '<C-s>', '<Cmd>w<CR>', opts)

    -- Multi-cursor support
    vim.keymap.set('n', '<C-d>', function() vscode.action('editor.action.addSelectionToNextFindMatch') end, opts)
    vim.keymap.set('n', '<C-S-l>', function() vscode.action('editor.action.selectHighlights') end, opts)

    -- Line manipulation
    vim.keymap.set('n', '<A-j>', function() vscode.action('editor.action.moveLinesDownAction') end, opts)
    vim.keymap.set('n', '<A-k>', function() vscode.action('editor.action.moveLinesUpAction') end, opts)
    vim.keymap.set('v', '<A-j>', [[:m '>+1<CR>gv=gv]], opts)
    vim.keymap.set('v', '<A-k>', [[:m '<-2<CR>gv=gv]], opts)

    -- Visual mode improvements
    vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", opts)
    vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", opts)
    vim.keymap.set('v', '<', '<gv', opts)
    vim.keymap.set('v', '>', '>gv', opts)

    -- Keep cursor centered
    vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
    vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)
    vim.keymap.set('n', 'n', 'nzzzv', opts)
    vim.keymap.set('n', 'N', 'Nzzzv', opts)

    -- Yank improvements
    vim.keymap.set({'n', 'v'}, '<leader>y', [["+y]], opts)
    vim.keymap.set('n', '<leader>Y', [["+Y]], opts)

    -- Toggle functionality
    vim.keymap.set('n', '<leader>to', function() vscode.action('outline.focus') end, opts)
    vim.keymap.set('n', '<leader>tc', function() vscode.action('github.copilot.chat.focus') end, opts)
    vim.keymap.set('n', '<leader>tm', function() vscode.action('workbench.action.showCommands') end, opts)
    vim.keymap.set('n', '<leader>tb', function() vscode.action('workbench.action.focusActiveEditorGroup') end, opts)
    
    -- Additional quick access without leader key
    vim.keymap.set('n', '<C-p>', function() vscode.action('workbench.action.showCommands') end, opts)
    vim.keymap.set('n', '<Esc><Esc>', function() vscode.action('workbench.action.focusActiveEditorGroup') end, opts)

    -- Folding
    vim.keymap.set('n', 'za', function() vscode.action('editor.toggleFold') end, opts)
    vim.keymap.set('n', 'zR', function() vscode.action('editor.unfoldAll') end, opts)
    vim.keymap.set('n', 'zM', function() vscode.action('editor.foldAll') end, opts)
end

return M
