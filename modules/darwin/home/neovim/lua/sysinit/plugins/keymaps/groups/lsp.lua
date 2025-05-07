-- lsp.lua
-- LSP keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register LSP group with the main keymaps module
    keymaps.register_group("l", keymaps.group_icons.lsp .. " LSP", {
        {
            key = "d",
            desc = "Go to Definition",
            neovim_cmd = "<cmd>lua vim.lsp.buf.definition()<CR>",
            vscode_cmd = "editor.action.revealDefinition"
        },
        {
            key = "r",
            desc = "Find References",
            neovim_cmd = "<cmd>lua vim.lsp.buf.references()<CR>",
            vscode_cmd = "editor.action.goToReferences"
        },
        {
            key = "h",
            desc = "Hover",
            neovim_cmd = "<cmd>lua vim.lsp.buf.hover()<CR>",
            vscode_cmd = "editor.action.showHover"
        },
        {
            key = "i",
            desc = "Implementation",
            neovim_cmd = "<cmd>lua vim.lsp.buf.implementation()<CR>",
            vscode_cmd = "editor.action.goToImplementation"
        }
    })
end

-- Add any LSP-specific plugins here
M.plugins = {}

return M