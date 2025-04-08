-- VSCode specific Neovim configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set timeout for keymaps to make which-key more responsive
vim.o.timeout = true
vim.o.timeoutlen = 300

-- VSCode specific keybindings
local vscode = require('vscode')

-- File navigation
vim.keymap.set('n', '<leader>ff', function() vscode.action('workbench.action.quickOpen') end)
vim.keymap.set('n', '<leader>fg', function() vscode.action('workbench.action.findInFiles') end)
vim.keymap.set('n', '<leader>fb', function() vscode.action('workbench.action.showAllEditors') end)
vim.keymap.set('n', '<leader>e', function() vscode.action('workbench.action.toggleSidebarVisibility') end)

-- LSP bindings
vim.keymap.set('n', 'gd', function() vscode.action('editor.action.revealDefinition') end)
vim.keymap.set('n', 'gr', function() vscode.action('editor.action.goToReferences') end)
vim.keymap.set('n', 'gi', function() vscode.action('editor.action.goToImplementation') end)
vim.keymap.set('n', 'K', function() vscode.action('editor.action.showHover') end)
vim.keymap.set('n', '<leader>rn', function() vscode.action('editor.action.rename') end)
vim.keymap.set('n', '<leader>ca', function() vscode.action('editor.action.quickFix') end)

-- Window navigation
vim.keymap.set('n', '<C-h>', function() vscode.action('workbench.action.navigateLeft') end)
vim.keymap.set('n', '<C-j>', function() vscode.action('workbench.action.navigateDown') end)
vim.keymap.set('n', '<C-k>', function() vscode.action('workbench.action.navigateUp') end)
vim.keymap.set('n', '<C-l>', function() vscode.action('workbench.action.navigateRight') end)

-- Window splitting
vim.keymap.set('n', '<leader>\\', function() vscode.action('workbench.action.splitEditor') end)
vim.keymap.set('n', '<leader>-', function() vscode.action('workbench.action.splitEditorDown') end)

-- Git integration
vim.keymap.set('n', '<leader>gb', function() vscode.action('gitlens.toggleLineBlame') end)
vim.keymap.set('n', '<leader>hs', function() vscode.action('git.stage') end)
vim.keymap.set('n', '<leader>hu', function() vscode.action('git.unstage') end)

-- Better window commands
vim.keymap.set('n', '<leader>wc', function() vscode.action('workbench.action.closeActiveEditor') end)
vim.keymap.set('n', '<leader>wo', function() vscode.action('workbench.action.closeOtherEditors') end)

-- File operations
vim.keymap.set('n', '<leader>pn', function()
  vscode.action('workbench.action.files.newUntitledFile')
end)

-- Multi-cursor support
vim.keymap.set('n', '<C-d>', function()
  vscode.with_insert(function()
    vscode.action("editor.action.addSelectionToNextFindMatch")
  end)
end)

-- Terminal integration
vim.keymap.set('n', '<C-\\>', function() vscode.action('workbench.action.terminal.toggleTerminal') end)

-- Detect if we're in vscode
if vim.g.vscode then
    -- VSCode extension
    local function copy()
      if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then
        local backup = vim.fn.getreg('a')
        vim.cmd('normal! "ay')
        vscode.action('workbench.action.files.save')
        vim.fn.setreg('a', backup)
      end
    end

    -- Add copy command
    vim.keymap.set('v', '<C-c>', copy)
end

-- Configure which-key to show on space
vim.keymap.set('n', '<Space>', function()
  vscode.action('whichkey.show')
end, { silent = true })