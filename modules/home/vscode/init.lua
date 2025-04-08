-- VSCode specific Neovim configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set timeout for keymaps
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Enable system clipboard integration
vim.opt.clipboard:append("unnamedplus")

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
        -- Function to check if we're in a context where WhichKey should be disabled
        local function should_disable_whichkey()
            -- Get the current buffer's filetype
            local filetype = vim.bo.filetype
            
            -- Check if we're in insert mode
            local in_insert = vim.fn.mode() == 'i'
            
            -- Check if we're in specific file types where we don't want WhichKey
            local blocked_filetypes = {
                ["github-actions-workflow"] = true,
                ["yaml.github-actions"] = true,
                ["TelescopePrompt"] = true,
            }
            
            -- Check if we're in a rename prompt or command palette
            local in_command = vim.fn.getcmdtype() ~= ''
            
            return in_insert or blocked_filetypes[filetype] or in_command
        end

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
            disable = {
                filetypes = { "TelescopePrompt", "github-actions-workflow", "yaml.github-actions" },
                buftypes = { "prompt", "popup" },
            },
            triggers_nowait = {
                -- These keys will trigger immediately even in insert mode
                "`",
                "'",
                "g`",
                "g'",
                '"',
                "<c-r>",
                "z=",
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
            ignore_missing = true,  -- Don't show errors for undefined mappings
            hidden = {
                "<silent>", "<cmd>", "<Cmd>", "<CR>", "^:", "^ ", "^call ", "^lua "
            },
            show_help = false,  -- Don't show help message
            show_keys = false,  -- Don't show key binding in command line
            timeout = {
                delay = 200,    -- Faster timeout
                interrupt = true  -- Allow interrupting the timeout
            },
            defaults = {
                mode = { "n", "v" },
                ["<leader>"] = {
                    f = {
                        name = "+find/files",
                        f = { function() vscode.action('workbench.action.quickOpen') end, "Find file" },
                        g = { function() vscode.action('workbench.action.findInFiles') end, "Find in files" },
                        b = { function() vscode.action('workbench.action.showAllEditors') end, "Show buffers" },
                        r = { function() vscode.action('fileutils.renameFile') end, "Rename file" },
                    },
                    b = {
                        name = "+buffer",
                        d = { function() vscode.action('workbench.action.closeActiveEditor') end, "Delete buffer" },
                        n = { function() vscode.action('workbench.action.nextEditor') end, "Next buffer" },
                        p = { function() vscode.action('workbench.action.previousEditor') end, "Previous buffer" },
                    },
                    w = {
                        name = "+workspace",
                        s = { function() vscode.action('workbench.action.splitEditor') end, "Split vertical" },
                        v = { function() vscode.action('workbench.action.splitEditorDown') end, "Split horizontal" },
                        q = { function() vscode.action('workbench.action.closeActiveEditor') end, "Close window" },
                        o = { function() vscode.action('workbench.action.closeOtherEditors') end, "Close others" },
                    },
                    c = {
                        name = "+code/copilot",
                        a = { function() vscode.action('editor.action.quickFix') end, "Code actions" },
                        r = { function() vscode.action('editor.action.rename') end, "Rename symbol" },
                        f = { function() vscode.action('editor.action.formatDocument') end, "Format document" },
                    },
                    e = { function() vscode.action('workbench.view.explorer') end, "Explorer" },
                    g = {
                        name = "+git",
                        s = { function() vscode.action('workbench.view.scm') end, "Source control" },
                        b = { function() vscode.action('git.checkout') end, "Checkout branch" },
                        c = { function() 
                            vscode.action('github.copilot.sourceControl.generateCommitMessage')
                            vim.defer_fn(function()
                                vscode.action('workbench.scm.focus')
                            end, 100)
                        end, "Commit (Copilot)" },
                        d = { function() vscode.action('git.openChange') end, "View diff" },
                    },
                    l = {
                        name = "+lsp",
                        d = { function() vscode.action('editor.action.revealDefinition') end, "Go to definition" },
                        r = { function() vscode.action('editor.action.goToReferences') end, "Go to references" },
                        i = { function() vscode.action('editor.action.showHover') end, "Show hover" },
                        s = { function() vscode.action('editor.action.showCallHierarchy') end, "Show call hierarchy" },
                        p = { function() vscode.action('editor.action.peekDefinition') end, "Peek definition" },
                        h = { function() vscode.action('editor.action.triggerParameterHints') end, "Parameter hints" },
                    },
                    d = {
                        name = "+debug",
                        i = { function() vscode.action('workbench.action.debug.stepInto') end, "Step into" },
                        o = { function() vscode.action('workbench.action.debug.stepOut') end, "Step out" },
                        n = { function() vscode.action('workbench.action.debug.stepOver') end, "Step over" },
                        c = { function() vscode.action('workbench.action.debug.continue') end, "Continue" },
                        b = { function() vscode.action('editor.debug.action.toggleBreakpoint') end, "Toggle breakpoint" },
                        s = { function() vscode.action('workbench.action.debug.start') end, "Start debugging" },
                        x = { function() vscode.action('workbench.action.debug.stop') end, "Stop debugging" },
                        v = { function() vscode.action('workbench.debug.action.toggleRepl') end, "Toggle debug console" },
                    },
                    t = {
                        name = "+toggle",
                        t = { function() vscode.action('workbench.action.terminal.toggleTerminal') end, "Terminal" },
                        p = { function() vscode.action('workbench.action.togglePanel') end, "Panel" },
                        s = { function() vscode.action('workbench.action.toggleSidebarVisibility') end, "Sidebar" },
                        c = { function() vscode.action('workbench.panel.chat.toggle') end, "Copilot Chat" },
                        o = { function() vscode.action('outline.focus') end, "Outline" },
                        -- Toggle Sticky Scroll
                        k = { function() 
                            local current = vscode.get_config("editor.stickyScroll.enabled")
                            vscode.update_config("editor.stickyScroll.enabled", not current)
                        end, "Toggle Sticky Scroll" },
                    },
                    x = {
                        name = "+diagnostics",
                        x = { function() vscode.action('workbench.actions.view.problems') end, "Show problems" },
                        n = { function() vscode.action('editor.action.marker.next') end, "Next problem" },
                        p = { function() vscode.action('editor.action.marker.prev') end, "Previous problem" },
                    },
                },
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
            -- Enhanced autocomplete and navigation
            ["<Tab>"] = { function() 
                if vim.fn.pumvisible() == 1 then
                    vscode.action('selectNextSuggestion')
                else
                    vscode.action('editor.action.triggerSuggest')
                end
            end, "Next suggestion" },
            ["<S-Tab>"] = { function()
                if vim.fn.pumvisible() == 1 then
                    vscode.action('selectPrevSuggestion')
                end
            end, "Previous suggestion" },
            ["gi"] = { function() vscode.action('editor.action.goToImplementation') end, "Go to implementation" },
            ["gh"] = { function() vscode.action('editor.action.showHover') end, "Show hover" },
            ["gk"] = { function() vscode.action('editor.action.showCallHierarchy') end, "Show call hierarchy" },
            -- Quick sticky scroll navigation
            ["[s"] = { function() vscode.action('editor.action.previousStickyScrollLine') end, "Previous sticky" },
            ["]s"] = { function() vscode.action('editor.action.nextStickyScrollLine') end, "Next sticky" },
            -- Quick view switching (Copilot Chat <-> Outline)
            ["<leader>vc"] = { function() vscode.action('workbench.panel.chat.toggle') end, "Toggle Copilot Chat" },
            ["<leader>vo"] = { function() vscode.action('outline.focus') end, "Toggle Outline" },
            -- Focus sticky scroll (useful when you want to interact with sticky header)
            ["gs"] = { function() vscode.action('editor.action.focusStickyScroll') end, "Focus sticky scroll" },
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