-- VSCode specific Neovim configuration
local opts = { noremap = true, silent = true }
local vscode = require("vscode")

vim.notify = vscode.notify

vim.keymap.set("n", "<SPACE>", "<NOP>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Clipboard interaction
vim.g.clipboard = vim.g.vscode_clipboard
vim.opt["clipboard"] = "unnamedplus"
vim.keymap.set("v", "p", '"_dP', opts)

-- Editor keybindings
vim.keymap.set("n", "<leader>e", function()
    vscode.action("workbench.action.closeSidebar")
    vscode.action("workbench.action.closePanel")
end, opts)

vim.keymap.set("n", "<leader>b", function()
    vscode.action("workbench.action.toggleSidebarVisibility")
end, opts)

vim.keymap.set("n", "<leader>j", function()
    vscode.action("workbench.action.togglePanel")
end, opts)

-- File explorer
vim.keymap.set("n", "-", function()
    vscode.action("workbench.files.action.showActiveFileInExplorer")
end, opts)

-- Window navigation
vim.keymap.set("n", "<C-h>", function()
    vscode.action("workbench.action.navigateLeft")
end, opts)
vim.keymap.set("n", "<C-j>", function()
    vscode.action("workbench.action.navigateDown")
end, opts)
vim.keymap.set("n", "<C-k>", function()
    vscode.action("workbench.action.navigateUp")
end, opts)
vim.keymap.set("n", "<C-l>", function()
    vscode.action("workbench.action.navigateRight")
end, opts)

-- Tab navigation
vim.keymap.set("n", "<S-h>", function()
    vscode.action("workbench.action.previousEditorInGroup")
end, opts)
vim.keymap.set("n", "<S-l>", function()
    vscode.action("workbench.action.nextEditorInGroup")
end, opts)

-- LSP keybindings
vim.keymap.set("n", "gr", function()
    vscode.action("editor.action.goToReferences")
end, opts)
vim.keymap.set("n", "<C-/>", function()
    vscode.action("editor.action.quickFix")
end, opts)
vim.keymap.set("n", "<S-k>", function()
    vscode.action("editor.action.showHover")
end, opts)
vim.keymap.set("n", "<leader>rr", function()
    vscode.action("editor.action.rename")
end, opts)

-- Errors navigation
vim.keymap.set("n", "]d", function()
    vscode.action("editor.action.marker.next")
end, opts)
vim.keymap.set("n", "[d", function()
    vscode.action("editor.action.marker.prev")
end, opts)

-- Source control
vim.keymap.set("n", "<leader>go", function()
    vscode.action("workbench.scm.focus")
end, opts)
vim.keymap.set("n", "<leader>gp", function()
    vscode.action("git.pull")
end, opts)
vim.keymap.set("n", "<leader>gP", function()
    vscode.action("git.push")
end, opts)

-- Finding and searching
vim.keymap.set("n", "<leader>ff", function()
    vscode.action("workbench.action.quickOpen")
end, opts)
vim.keymap.set("n", "<leader>ft", function()
    vscode.action("workbench.action.quickTextSearch")
end, opts)

-- Tasks
vim.keymap.set("n", "<leader>tr", function()
    vscode.action("workbench.action.tasks.runTask")
end, opts)

-- Debugger
vim.keymap.set("n", "<leader>db", function()
    vscode.action("editor.debug.action.toggleBreakpoint")
end, opts)
vim.keymap.set("n", "<leader>dc", function()
    vscode.action("workbench.action.debug.continue")
end, opts)

-- Visual mode enhancements
vim.keymap.set("v", "<", "<gv^", opts)
vim.keymap.set("v", ">", ">gv^", opts)
vim.keymap.set("v", "p", "pgvy", opts)

-- Remove WhichKey integration and replace it with Lua-based keybinding descriptions

-- Define a table for keybinding descriptions
local keybindings = {
    f = {
        name = "File",
        bindings = {
            { key = "f", description = "Find File", action = "workbench.action.quickOpen" },
            { key = "t", description = "Text Search", action = "workbench.action.quickTextSearch" }
        }
    },
    g = {
        name = "Git",
        bindings = {
            { key = "p", description = "Pull", action = "git.pull" },
            { key = "P", description = "Push", action = "git.push" }
        }
    }
}

-- Function to set keybindings based on the table
local function set_keybindings(prefix, bindings)
    for _, binding in ipairs(bindings) do
        local key = prefix .. binding.key
        vim.keymap.set("n", key, function()
            vscode.action(binding.action)
        end, opts)
    end
end

-- Apply keybindings
for prefix, group in pairs(keybindings) do
    set_keybindings("<leader>" .. prefix, group.bindings)
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