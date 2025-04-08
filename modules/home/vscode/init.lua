-- VSCode specific Neovim configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set timeout for keymaps
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Enable system clipboard integration
vim.opt.clipboard:append("unnamedplus")

-- Configure VSCode Vim to use space as menu trigger
if vim.g.vscode then
    local vscode = require('vscode')
    
    -- Setup WhichKey with lazy.nvim pattern
    local whichkey = {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
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
            window = {
                border = "single",
                position = "bottom",
                margin = { 1, 0, 1, 0 },
                padding = { 1, 1, 1, 1 },
                winblend = 0
            },
            layout = {
                height = { min = 3, max = 25 },
                width = { min = 20, max = 50 },
                spacing = 3,
                align = "left",
            },
            show_help = true,
            triggers = "auto",
        },
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = " Buffer Local Keymaps",
            },
        },
        config = function(_, opts)
            local wk = require("which-key")
            wk.setup(opts)

            -- Register keybindings with icons
            wk.register({
                ["<leader>f"] = {
                    name = " File",
                    f = { function() vscode.action("search-preview.quickOpenWithPreview") end, " Find File" },
                    r = { function() vscode.action("search-preview.showAllEditorsByMostRecentlyUsed") end, "󰋚 Recent Files" },
                    g = { function() vscode.action("workbench.action.findInFiles") end, " Find in Files" },
                    b = { function() vscode.action("workbench.action.showAllEditors") end, "󰓩 Show Buffers" },
                    n = { function() vscode.action("fileutils.renameFile") end, " Rename File" },
                    s = { function() vscode.action("search-preview.openSearchSettings") end, " Search Settings" },
                },
                ["<leader>w"] = {
                    name = "󱂬 Window",
                    v = { function() vscode.action("workbench.action.splitEditor") end, "󰤱 Split Vertical" },
                    h = { function() vscode.action("workbench.action.splitEditorDown") end, "󰤲 Split Horizontal" },
                    q = { function() vscode.action("workbench.action.closeActiveEditor") end, " Close Window" },
                    o = { function() vscode.action("workbench.action.closeOtherEditors") end, " Close Others" },
                    ["H"] = { function() vscode.action("workbench.action.focusLeftGroup") end, " Focus Left" },
                    ["L"] = { function() vscode.action("workbench.action.focusRightGroup") end, " Focus Right" },
                    ["K"] = { function() vscode.action("workbench.action.focusAboveGroup") end, " Focus Up" },
                    ["J"] = { function() vscode.action("workbench.action.focusBelowGroup") end, " Focus Down" },
                },
                ["<leader>t"] = {
                    name = " Toggle",
                    t = { function() vscode.action("workbench.action.terminal.toggleTerminal") end, " Terminal" },
                    p = { function() vscode.action("workbench.action.togglePanel") end, " Panel" },
                    s = { function() vscode.action("workbench.action.toggleSidebarVisibility") end, " Sidebar" },
                    c = { function() vscode.action("workbench.panel.chat.toggle") end, "󰚩 Copilot Chat" },
                    o = { function() vscode.action("outline.focus") end, "󰙴 Outline" },
                },
                ["<leader>g"] = {
                    name = " Git",
                    s = { function() vscode.action("workbench.view.scm") end, " Source Control" },
                    b = { function() vscode.action("git.checkout") end, " Checkout Branch" },
                    c = { function() 
                        vscode.action("github.copilot.sourceControl.generateCommitMessage")
                        vscode.action("workbench.scm.focus", { delay = 100 })
                    end, " Commit (Copilot)" },
                    d = { function() vscode.action("git.openChange") end, "󰜄 View Diff" },
                },
                ["<leader>e"] = { function() vscode.action("workbench.view.explorer") end, " Explorer" },
                ["<leader><leader>"] = { function() vscode.action("search-preview.showAllEditorsByMostRecentlyUsed") end, "󰋚 Recent Files" },
            })
        end,
    }

    -- Load WhichKey configuration
    require("lazy").setup({ whichkey })
end

-- Configure enhanced cursor appearance for different modes
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