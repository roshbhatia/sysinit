-- notifications.lua
-- Notifications keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register notifications group with the main keymaps module
    keymaps.register_group("n", keymaps.group_icons.notifications .. " Notifications", {
        {
            key = "c",
            desc = "Clear All",
            neovim_cmd = "<cmd>Fidget clear<CR>",
            vscode_cmd = "notifications.clearAll"
        },
        {
            key = "t",
            desc = "Toggle",
            neovim_cmd = "<cmd>Fidget history<CR>",
            vscode_cmd = "notifications.toggleList"
        }
    })
end

-- Add any notifications-specific plugins here
M.plugins = {}

return M