-- code.lua
-- Code operations keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register code group with the main keymaps module
    keymaps.register_group("c", keymaps.group_icons.code .. " Code", {
        {
            key = "a",
            desc = "Code Actions",
            neovim_cmd = "<cmd>lua vim.lsp.buf.code_action()<CR>",
            vscode_cmd = "editor.action.sourceAction"
        },
        {
            key = "c",
            desc = "Toggle Comment",
            neovim_cmd = "<Plug>(comment_toggle_linewise_current)",
            vscode_cmd = "editor.action.commentLine"
        },
        {
            key = "f",
            desc = "Format Document",
            neovim_cmd = "<cmd>lua vim.lsp.buf.format()<CR>",
            vscode_cmd = "editor.action.formatDocument"
        },
        {
            key = "r",
            desc = "Rename Symbol",
            neovim_cmd = "<cmd>lua vim.lsp.buf.rename()<CR>",
            vscode_cmd = "editor.action.rename"
        }
    })
end

-- Add any code-specific plugins here
M.plugins = {}

return M