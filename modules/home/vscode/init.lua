-- VSCode specific Neovim configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set timeout for keymaps
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Enable system clipboard integration
vim.opt.clipboard:append("unnamedplus")

if vim.g.vscode then
    local vscode = require('vscode')
    local wk = require("which-key")
    
    -- Setup which-key with v3 configuration
    wk.setup({
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
        icons = {
            breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
            separator = "➜", -- symbol used between a key and it's label
            group = "+", -- symbol prepended to a group
            mappings = {
                color = "blue",
                cat = "extension". 
            },
        },
        win = {
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
        triggers = { -- v3 triggers configuration
            { "<auto>", mode = "nixsotc" },
        },
    })

    -- Register keybindings using v3 spec
    wk.add({
        -- Groups
        { "<leader>f", group = "File", icon = { icon = "󰈔", color = "blue" } },
        { "<leader>w", group = "Window", icon = { icon = "󱂬", color = "cyan" } },
        { "<leader>t", group = "Toggle", icon = { icon = "󰌓", color = "orange" } },
        { "<leader>g", group = "Git", icon = { icon = "󰊢", color = "red" } },

        -- File operations
        { "<leader>ff", function() vscode.action("search-preview.quickOpenWithPreview") end, desc = "Find File", icon = { icon = "󰈞", color = "blue" } },
        { "<leader>fr", function() vscode.action("search-preview.showAllEditorsByMostRecentlyUsed") end, desc = "Recent Files", icon = { icon = "󰋚", color = "purple" } },
        { "<leader>fg", function() vscode.action("workbench.action.findInFiles") end, desc = "Find in Files", icon = { icon = "󰈭", color = "yellow" } },
        { "<leader>fb", function() vscode.action("workbench.action.showAllEditors") end, desc = "Show Buffers", icon = { icon = "󰓩", color = "azure" } },
        { "<leader>fn", function() vscode.action("fileutils.renameFile") end, desc = "Rename File", icon = { icon = "󰑕", color = "orange" } },
        { "<leader>fs", function() vscode.action("search-preview.openSearchSettings") end, desc = "Search Settings", icon = { icon = "󰒓", color = "purple" } },

        -- Window operations
        { "<leader>wv", function() vscode.action("workbench.action.splitEditor") end, desc = "Split Vertical", icon = { icon = "󰤱", color = "cyan" } },
        { "<leader>wh", function() vscode.action("workbench.action.splitEditorDown") end, desc = "Split Horizontal", icon = { icon = "󰤲", color = "cyan" } },
        { "<leader>wq", function() vscode.action("workbench.action.closeActiveEditor") end, desc = "Close Window", icon = { icon = "󰖭", color = "red" } },
        { "<leader>wo", function() vscode.action("workbench.action.closeOtherEditors") end, desc = "Close Others", icon = { icon = "󰝥", color = "red" } },
        { "<leader>wH", function() vscode.action("workbench.action.focusLeftGroup") end, desc = "Focus Left", icon = { icon = "󰁍", color = "blue" } },
        { "<leader>wL", function() vscode.action("workbench.action.focusRightGroup") end, desc = "Focus Right", icon = { icon = "󰁅", color = "blue" } },
        { "<leader>wK", function() vscode.action("workbench.action.focusAboveGroup") end, desc = "Focus Up", icon = { icon = "󰁃", color = "blue" } },
        { "<leader>wJ", function() vscode.action("workbench.action.focusBelowGroup") end, desc = "Focus Down", icon = { icon = "󰁯", color = "blue" } },

        -- Toggle operations
        { "<leader>tt", function() vscode.action("workbench.action.terminal.toggleTerminal") end, desc = "Terminal", icon = { icon = "󰆍", color = "green" } },
        { "<leader>tp", function() vscode.action("workbench.action.togglePanel") end, desc = "Panel", icon = { icon = "󰧩", color = "orange" } },
        { "<leader>ts", function() vscode.action("workbench.action.toggleSidebarVisibility") end, desc = "Sidebar", icon = { icon = "󰬷", color = "orange" } },
        { "<leader>tc", function() vscode.action("workbench.panel.chat.toggle") end, desc = "Copilot Chat", icon = { icon = "󰚩", color = "green" } },
        { "<leader>to", function() vscode.action("outline.focus") end, desc = "Outline", icon = { icon = "󰙴", color = "blue" } },

        -- Git operations
        { "<leader>gs", function() vscode.action("workbench.view.scm") end, desc = "Source Control", icon = { icon = "󰊢", color = "red" } },
        { "<leader>gb", function() vscode.action("git.checkout") end, desc = "Checkout Branch", icon = { icon = "󰘬", color = "purple" } },
        { "<leader>gc", function() 
            vscode.action("github.copilot.sourceControl.generateCommitMessage")
            vscode.action("workbench.scm.focus", { delay = 100 })
        end, desc = "Commit (Copilot)", icon = { icon = "󰊢", color = "green" } },
        { "<leader>gd", function() vscode.action("git.openChange") end, desc = "View Diff", icon = { icon = "󰜄", color = "blue" } },

        -- Special bindings
        { "<leader>e", function() vscode.action("workbench.view.explorer") end, desc = "Explorer", icon = { icon = "󰙅", color = "blue" } },
        { "<leader><leader>", function() vscode.action("search-preview.showAllEditorsByMostRecentlyUsed") end, desc = "Recent Files", mode = { "n" }, icon = { icon = "󰋚", color = "purple" } },
        { "<leader>?", function() wk.show() end, desc = "Show Keybindings", icon = { icon = "󰞋", color = "blue" } },
    })
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