-- VSCode specific Neovim configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set timeout for keymaps
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Configure enhanced cursor appearance for different modes
-- Uses custom cursor shapes and colors per mode:
-- Normal: Block cursor with orange color
-- Insert: Line cursor with bright green color
-- Visual: Block cursor with purple color
-- Replace: Underline cursor with red color
vim.opt.guicursor = table.concat({
    "n-c:block-blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
    "i-ci-ve:ver25-blinkwait400-blinkoff250-blinkon500-CursorIM/lCursor",
    "v-sm:block-blinkwait175-blinkoff150-blinkon175-Visual/lCursor",
    "r-cr-o:hor20-blinkwait700-blinkoff400-blinkon250-CursorRM/lCursor"
}, ",")

-- Create highlight groups for different cursor modes
vim.api.nvim_create_autocmd({"ColorScheme", "VimEnter"}, {
    callback = function()
        -- Normal mode cursor (orange)
        vim.api.nvim_set_hl(0, "Cursor", { fg = "#282828", bg = "#fe8019" })
        -- Insert mode cursor (bright green)
        vim.api.nvim_set_hl(0, "CursorIM", { fg = "#282828", bg = "#b8bb26" })
        -- Visual mode cursor (purple)
        vim.api.nvim_set_hl(0, "Visual", { fg = "#282828", bg = "#d3869b" })
        -- Replace mode cursor (red)
        vim.api.nvim_set_hl(0, "CursorRM", { fg = "#282828", bg = "#fb4934" })
    end
})

-- Only load VSCode-specific configurations when running inside VSCode
if vim.g.vscode then
    local vscode = require('vscode')
    
    -- Setup which-key
    local ok, which_key = pcall(require, "which-key")
    if ok then
        which_key.setup({
            plugins = {
                marks = true,
                registers = true,
                spelling = { enabled = false },
                presets = {
                    operators = false,    -- Don't show built-in operators
                    motions = false,      -- Don't show built-in motions
                    text_objects = false, -- Don't show built-in text objects
                    windows = false,      -- Don't show built-in windows operations
                    nav = false,          -- Don't show built-in navs
                    z = false,            -- Don't show built-in z operations
                    g = false,            -- Don't show built-in g operations
                },
            },
            window = {
                border = "single",
                position = "bottom",
                margin = { 1, 0, 1, 0 },
                padding = { 1, 1, 1, 1 },
            },
            layout = {
                height = { min = 3, max = 25 },
                width = { min = 20, max = 50 },
                spacing = 3,
                align = "left",
            },
        })

        -- Register key groups and mappings
        which_key.register({
            ["<leader>"] = {
                f = {
                    name = "+find/file",
                    f = { function() vscode.action('workbench.action.quickOpen') end, "Find file" },
                    g = { function() vscode.action('workbench.action.findInFiles') end, "Find in files" },
                    b = { function() vscode.action('workbench.action.showAllEditors') end, "Show all buffers" },
                    d = { function()
                        vscode.action('workbench.files.action.showActiveFileInExplorer')
                        vim.defer_fn(function()
                            vscode.action('filesExplorer.copy')
                        end, 100)
                    end, "Duplicate file" },
                    D = { function()
                        vscode.action('workbench.files.action.showActiveFileInExplorer')
                        vim.defer_fn(function()
                            vscode.action('filesExplorer.paste')
                        end, 100)
                    end, "Duplicate folder" },
                    m = { function() vscode.action('fileutils.moveFile') end, "Move file" },
                    r = { function() vscode.action('fileutils.renameFile') end, "Rename file" },
                },
                w = {
                    name = "+window",
                    v = { function() vscode.action('workbench.action.splitEditor') end, "Split vertical" },
                    h = { function() vscode.action('workbench.action.splitEditorDown') end, "Split horizontal" },
                    q = { function() vscode.action('workbench.action.closeActiveEditor') end, "Close window" },
                    o = { function() vscode.action('workbench.action.closeOtherEditors') end, "Close others" },
                    -- Active pane focus commands
                    H = { function() vscode.action('workbench.action.focusLeftGroup') end, "Focus left pane" },
                    L = { function() vscode.action('workbench.action.focusRightGroup') end, "Focus right pane" },
                    K = { function() vscode.action('workbench.action.focusAboveGroup') end, "Focus above pane" },
                    J = { function() vscode.action('workbench.action.focusBelowGroup') end, "Focus below pane" },
                },
                g = {
                    name = "+git",
                    s = { function() vscode.action('workbench.view.scm') end, "Source control" },
                    a = { function() vscode.action('git.stage') end, "Stage changes" },
                    u = { function() vscode.action('git.unstage') end, "Unstage changes" },
                    A = { function() vscode.action('git.stageAll') end, "Stage all" },
                    U = { function() vscode.action('git.unstageAll') end, "Unstage all" },
                    c = { function() 
                        vscode.action('github.copilot.sourceControl.generateCommitMessage')
                        vim.defer_fn(function()
                            vscode.action('workbench.scm.focus')
                        end, 100)
                    end, "Commit (with Copilot)" },
                    p = { function() vscode.action('git.push') end, "Push" },
                    d = { function() vscode.action('git.openChange') end, "View diff" },
                    l = { function() vscode.action('git.openFile') end, "Open file" },
                },
                e = { function() vscode.action('workbench.view.explorer') end, "Explorer" },
                t = { function() vscode.action('workbench.action.terminal.toggleTerminal') end, "Toggle terminal" },
            },
            -- Quick tab switching without leader key
            ["<C-n>"] = { function() vscode.action('workbench.action.nextEditor') end, "Next tab" },
            ["<C-p>"] = { function() vscode.action('workbench.action.previousEditor') end, "Previous tab" },
            -- Quick pane switching without leader key
            ["<M-h>"] = { function() vscode.action('workbench.action.focusLeftGroup') end, "Focus left pane" },
            ["<M-l>"] = { function() vscode.action('workbench.action.focusRightGroup') end, "Focus right pane" },
            ["<M-k>"] = { function() vscode.action('workbench.action.focusAboveGroup') end, "Focus above pane" },
            ["<M-j>"] = { function() vscode.action('workbench.action.focusBelowGroup') end, "Focus below pane" },
        })
    end

    -- Window navigation
    vim.keymap.set('n', '<C-h>', function() vscode.action('workbench.action.navigateLeft') end)
    vim.keymap.set('n', '<C-j>', function() vscode.action('workbench.action.navigateDown') end)
    vim.keymap.set('n', '<C-k>', function() vscode.action('workbench.action.navigateUp') end)
    vim.keymap.set('n', '<C-l>', function() vscode.action('workbench.action.navigateRight') end)

    -- Tab navigation
    vim.keymap.set('n', 'H', function() vscode.action('workbench.action.previousEditor') end)
    vim.keymap.set('n', 'L', function() vscode.action('workbench.action.nextEditor') end)
    
    -- Multi-cursor support
    vim.keymap.set('n', '<C-d>', function()
        vscode.with_insert(function()
            vscode.action("editor.action.addSelectionToNextFindMatch")
        end)
    end)

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