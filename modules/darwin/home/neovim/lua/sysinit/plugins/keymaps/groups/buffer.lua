-- buffer.lua
-- Buffer operations keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register buffer group with the main keymaps module
    keymaps.register_group("b", keymaps.group_icons.buffer .. " Buffer", {
        {
            key = "b",
            desc = "Show Buffers",
            neovim_cmd = "<cmd>Telescope buffers<CR>",
            vscode_cmd = "workbench.action.showAllEditors"
        },
        {
            key = "d",
            desc = "Close Buffer",
            neovim_cmd = "<cmd>bd<CR>",
            vscode_cmd = "workbench.action.closeActiveEditor"
        },
        {
            key = "n",
            desc = "Next Buffer",
            neovim_cmd = "<cmd>bnext<CR>",
            vscode_cmd = "workbench.action.nextEditor"
        },
        {
            key = "p",
            desc = "Previous Buffer",
            neovim_cmd = "<cmd>bprevious<CR>",
            vscode_cmd = "workbench.action.previousEditor"
        }
    })
end

-- Add any buffer-specific plugins here
M.plugins = {}

return M