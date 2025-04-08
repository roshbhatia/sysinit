-- VSCode specific Neovim configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set timeout for keymaps
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Configure cursor shapes for different modes
vim.opt.guicursor = "n-v-c:block-blinkon1,i-ci-ve:ver25-blinkon1,r-cr:hor20,o:hor50"

-- Only load VSCode-specific configurations when running inside VSCode
if vim.g.vscode then
    local vscode = require('vscode')
    
    -- Window navigation
    vim.keymap.set('n', '<C-h>', function() vscode.action('workbench.action.navigateLeft') end)
    vim.keymap.set('n', '<C-j>', function() vscode.action('workbench.action.navigateDown') end)
    vim.keymap.set('n', '<C-k>', function() vscode.action('workbench.action.navigateUp') end)
    vim.keymap.set('n', '<C-l>', function() vscode.action('workbench.action.navigateRight') end)

    -- Tab navigation
    vim.keymap.set('n', 'H', function() vscode.action('workbench.action.previousEditor') end)
    vim.keymap.set('n', 'L', function() vscode.action('workbench.action.nextEditor') end)

    -- Git keybindings
    -- Source control view
    vim.keymap.set('n', '<leader>gs', function() vscode.action('workbench.view.scm') end)
    
    -- Stage/unstage
    vim.keymap.set('n', '<leader>ga', function() vscode.action('git.stage') end)
    vim.keymap.set('n', '<leader>gu', function() vscode.action('git.unstage') end)
    vim.keymap.set('n', '<leader>gA', function() vscode.action('git.stageAll') end)
    vim.keymap.set('n', '<leader>gU', function() vscode.action('git.unstageAll') end)
    
    -- Commit and push
    vim.keymap.set('n', '<leader>gc', function() 
        -- First get Copilot suggestion for commit message
        vscode.action('github.copilot.sourceControl.generateCommitMessage')
        -- Wait a bit for Copilot to generate the message
        vim.defer_fn(function()
            vscode.action('workbench.scm.focus')
        end, 100)
    end)
    vim.keymap.set('n', '<leader>gp', function() vscode.action('git.push') end)
    
    -- Diff actions
    vim.keymap.set('n', '<leader>gd', function() vscode.action('git.openChange') end)
    vim.keymap.set('n', '<leader>gl', function() vscode.action('git.openFile') end)
    
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
end