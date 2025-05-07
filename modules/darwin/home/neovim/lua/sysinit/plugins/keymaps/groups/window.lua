-- window.lua
-- Window operation keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register window group with the main keymaps module
    keymaps.register_group("w", keymaps.group_icons.window .. " Window", {
        {
            key = "w",
            desc = "Save",
            neovim_cmd = "<cmd>w<CR>",
            vscode_cmd = "workbench.action.files.save"
        },
        {
            key = "q",
            desc = "Close Window",
            neovim_cmd = "<cmd>q<CR>",
            vscode_cmd = "workbench.action.closeWindow"
        }
    })
end

-- Add any window-specific plugins here
M.plugins = {}

return M