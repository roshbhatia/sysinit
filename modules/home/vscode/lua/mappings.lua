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

    -- Save operations
    vim.keymap.set('n', '<leader>w', function() vscode.action('workbench.action.files.save') end, opts)
    vim.keymap.set('n', '<leader>wa', function() vscode.action('workbench.action.files.saveAll') end, opts)
    
    -- Window splits (Neovim style)
    vim.keymap.set('n', '<leader>\\', function() vscode.action('workbench.action.splitEditorRight') end, opts)
    vim.keymap.set('n', '<leader>-', function() vscode.action('workbench.action.splitEditorDown') end, opts)

    -- Buffer/Tab operations 
    vim.keymap.set('n', '<leader>bd', function() vscode.action('workbench.action.closeActiveEditor') end, opts)
    vim.keymap.set('n', '<leader>bD', function() vscode.action('workbench.action.closeAllEditors') end, opts)
    vim.keymap.set('n', '<leader>bo', function() vscode.action('workbench.action.closeOtherEditors') end, opts)
    
    -- Find/Search (preserve VSCode's powerful search)
    vim.keymap.set('n', '<leader>ff', function() vscode.action('workbench.action.quickOpen') end, opts)
    vim.keymap.set('n', '<leader>fg', function() vscode.action('workbench.action.findInFiles') end, opts)
    vim.keymap.set('n', '<leader>fr', function() vscode.action('workbench.action.replaceInFiles') end, opts)

    -- LSP-like operations (using VSCode's native commands)
    vim.keymap.set('n', 'gd', function() vscode.action('editor.action.revealDefinition') end, opts)
    vim.keymap.set('n', 'gr', function() vscode.action('editor.action.goToReferences') end, opts)
    vim.keymap.set('n', 'gi', function() vscode.action('editor.action.goToImplementation') end, opts)
    vim.keymap.set('n', 'K', function() vscode.action('editor.action.showHover') end, opts)

    -- Git Integration (These complement the cmd+shift+g shortcuts in VSCode)
    vim.keymap.set('n', '<leader>gs', function() vscode.action('workbench.view.scm') end, opts)
    vim.keymap.set('n', '<leader>gc', function() vscode.action('git.commitAll') end, opts)
    vim.keymap.set('n', '<leader>gp', function() vscode.action('git.push') end, opts)
    vim.keymap.set('n', '<leader>gm', function() vscode.action('github.copilot.generateCommitMessage') end, opts)
    
    -- File operations
    vim.keymap.set('n', '<leader>fr', function() vscode.action('renameFile') end, opts)
    vim.keymap.set('n', '<leader>fd', function() vscode.action('duplicateFile') end, opts)

    -- Quick Access Commands (These mirror VSCode's native cmd shortcuts but work in Neovim mode)
    vim.keymap.set({'n', 'i'}, '<D-p>', function() vscode.action('workbench.action.quickOpen') end, opts)
    vim.keymap.set({'n', 'i'}, '<D-P>', function() vscode.action('workbench.action.showCommands') end, opts)
    
    -- Development tools (mirrors leader-based commands from keybindings.lua)
    vim.keymap.set('n', '<leader>dc', function() vscode.action('workbench.panel.chat.view.copilot.focus') end, opts)
    vim.keymap.set('n', '<leader>di', function() vscode.action('inlineChat.start') end, opts)
    vim.keymap.set('n', '<leader>dg', function() vscode.action('codegpt.explainCodeGPT') end, opts)
    vim.keymap.set('n', '<leader>dd', function() vscode.action('extension.addDocComments') end, opts)
    vim.keymap.set('n', '<leader>dh', function() vscode.action('editor.action.showHover') end, opts)

    -- Quick Toggles (These complement cmd+b and other VSCode toggles)
    vim.keymap.set('n', '<leader>e', function() vscode.action('workbench.action.toggleSidebarVisibility') end, opts)
    vim.keymap.set('n', '<leader>o', function() vscode.action('workbench.view.outline.focus') end, opts)
    vim.keymap.set('n', '<leader>t', function() vscode.action('workbench.action.terminal.toggleTerminal') end, opts)

    -- Code Actions (preserve VSCode's powerful features)
    vim.keymap.set('n', '<leader>ca', function() vscode.action('editor.action.quickFix') end, opts)
    vim.keymap.set('n', '<leader>cr', function() vscode.action('editor.action.rename') end, opts)
    vim.keymap.set('n', '<leader>cf', function() vscode.action('editor.action.formatDocument') end, opts)

    -- Comments (Vim style)
    vim.keymap.set('n', 'gcc', function() vscode.action('editor.action.commentLine') end, opts)
    vim.keymap.set('v', 'gc', function() vscode.action('editor.action.commentLine') end, opts)

    -- Navigation (LSP-style)
    vim.keymap.set('n', 'gd', function() vscode.action('editor.action.revealDefinition') end, opts)
    vim.keymap.set('n', 'gr', function() vscode.action('editor.action.goToReferences') end, opts)
    vim.keymap.set('n', 'gi', function() vscode.action('editor.action.goToImplementation') end, opts)
    vim.keymap.set('n', 'K', function() vscode.action('editor.action.showHover') end, opts)

    -- Quick escape from features
    vim.keymap.set('n', '<Esc><Esc>', function() vscode.action('workbench.action.focusActiveEditorGroup') end, opts)
    vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], opts)

    -- Keep cursor centered
    vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
    vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)
    vim.keymap.set('n', 'n', 'nzzzv', opts)
    vim.keymap.set('n', 'N', 'Nzzzv', opts)
end

return M
