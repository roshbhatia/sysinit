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
    
    -- Setup which-key with modern configuration
    local ok, which_key = pcall(require, "which-key")
    if ok then
        which_key.setup({
            plugins = {
                marks = true,
                registers = true,
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
            -- Modern options replacing deprecated ones
            defaults = {
                mode = { "n", "v" },
                ["<leader>"] = { prefix = "<leader>" },
            },
            icons = {
                breadcrumb = "»",
                separator = "➜",
                group = "+",
            },
            -- New window options
            win = {
                border = "single",
                position = "bottom",
                margin = { 1, 0, 1, 0 },
                padding = { 1, 1, 1, 1 },
                winblend = 0
            },
            -- New layout options
            layout = {
                height = { min = 3, max = 25 },
                width = { min = 20, max = 50 },
                spacing = 3,
                align = "left",
            },
            show = {
                help = true,
                keys = true,
            },
            -- New trigger options
            triggers = {
                { mode = "n", keys = { "<leader>" } },
                { mode = "v", keys = { "<leader>" } },
            },
            filter = {
                exclude = {
                    buftypes = { "prompt", "popup" },
                    filetypes = { "TelescopePrompt", "github-actions-workflow" }
                }
            }
        })

        -- Register mappings using the new format
        local mappings = {
            { "<leader>e", function() vscode.action('workbench.view.explorer') end, desc = "Explorer" },
            
            -- Find/files group
            { "<leader>f", group = "find/files" },
            { "<leader>ff", function() vscode.action('workbench.action.quickOpen') end, desc = "Find file" },
            { "<leader>fg", function() vscode.action('workbench.action.findInFiles') end, desc = "Find in files" },
            { "<leader>fb", function() vscode.action('workbench.action.showAllEditors') end, desc = "Show buffers" },
            { "<leader>fr", function() vscode.action('fileutils.renameFile') end, desc = "Rename file" },
            
            -- Window group
            { "<leader>w", group = "window" },
            { "<leader>wv", function() vscode.action('workbench.action.splitEditor') end, desc = "Split vertical" },
            { "<leader>wh", function() vscode.action('workbench.action.splitEditorDown') end, desc = "Split horizontal" },
            { "<leader>wq", function() vscode.action('workbench.action.closeActiveEditor') end, desc = "Close window" },
            { "<leader>wo", function() vscode.action('workbench.action.closeOtherEditors') end, desc = "Close others" },
            { "<leader>wH", function() vscode.action('workbench.action.focusLeftGroup') end, desc = "Focus left" },
            { "<leader>wL", function() vscode.action('workbench.action.focusRightGroup') end, desc = "Focus right" },
            { "<leader>wK", function() vscode.action('workbench.action.focusAboveGroup') end, desc = "Focus up" },
            { "<leader>wJ", function() vscode.action('workbench.action.focusBelowGroup') end, desc = "Focus down" },
            
            -- Toggle group
            { "<leader>t", group = "toggle" },
            { "<leader>tt", function() vscode.action('workbench.action.terminal.toggleTerminal') end, desc = "Terminal" },
            { "<leader>tp", function() vscode.action('workbench.action.togglePanel') end, desc = "Panel" },
            { "<leader>ts", function() vscode.action('workbench.action.toggleSidebarVisibility') end, desc = "Sidebar" },
            { "<leader>tc", function() vscode.action('workbench.panel.chat.toggle') end, desc = "Copilot Chat" },
            { "<leader>to", function() vscode.action('outline.focus') end, desc = "Outline" },
            
            -- Git group
            { "<leader>g", group = "git" },
            { "<leader>gs", function() vscode.action('workbench.view.scm') end, desc = "Source control" },
            { "<leader>gb", function() vscode.action('git.checkout') end, desc = "Checkout branch" },
            { "<leader>gc", function() 
                vscode.action('github.copilot.sourceControl.generateCommitMessage')
                vim.defer_fn(function()
                    vscode.action('workbench.scm.focus')
                end, 100)
            end, desc = "Commit (Copilot)" },
            { "<leader>gd", function() vscode.action('git.openChange') end, desc = "View diff" },
            
            -- Global mappings
            { "gh", function() vscode.action('editor.action.showHover') end, desc = "Show hover" },
            { "gk", function() vscode.action('editor.action.showCallHierarchy') end, desc = "Call hierarchy" },
            { "gi", function() vscode.action('editor.action.goToImplementation') end, desc = "Go to impl" },
            { "[s", function() vscode.action('editor.action.previousStickyScrollLine') end, desc = "Prev sticky" },
            { "]s", function() vscode.action('editor.action.nextStickyScrollLine') end, desc = "Next sticky" },
            { "gs", function() vscode.action('editor.action.focusStickyScroll') end, desc = "Focus sticky" },
        }

        -- Register all mappings at once with the new format
        which_key.register(mappings)
    end

    -- Register direct keymaps that don't need which-key
    local function set_keymap(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
    end

    -- Window navigation
    set_keymap('n', '<C-h>', function() vscode.action('workbench.action.navigateLeft') end, "Navigate left")
    set_keymap('n', '<C-j>', function() vscode.action('workbench.action.navigateDown') end, "Navigate down")
    set_keymap('n', '<C-k>', function() vscode.action('workbench.action.navigateUp') end, "Navigate up")
    set_keymap('n', '<C-l>', function() vscode.action('workbench.action.navigateRight') end, "Navigate right")

    -- Tab navigation
    set_keymap('n', 'H', function() vscode.action('workbench.action.previousEditor') end, "Previous editor")
    set_keymap('n', 'L', function() vscode.action('workbench.action.nextEditor') end, "Next editor")
    
    -- Multi-cursor and clipboard operations
    set_keymap('n', '<C-d>', function()
        vscode.with_insert(function()
            vscode.action("editor.action.addSelectionToNextFindMatch")
        end)
    end, "Add next occurrence")

    -- Enhanced clipboard operations
    local function copy()
        if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then
            local backup = vim.fn.getreg('a')
            vim.cmd('normal! "ay')
            vscode.action('workbench.action.files.save')
            vim.fn.setreg('a', backup)
        end
    end
    set_keymap('v', '<C-c>', copy, "Copy selection")
end