-- terminal.lua
-- Terminal keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register terminal group with the main keymaps module
    keymaps.register_group("t", keymaps.group_icons.terminal .. " Terminal", {
        {
            key = "t",
            desc = "Toggle Terminal",
            neovim_cmd = "<cmd>ToggleTerm<CR>",
            vscode_cmd = "workbench.action.terminal.toggleTerminal"
        }
    })
end

-- Add any terminal-specific plugins here
M.plugins = {}

return M