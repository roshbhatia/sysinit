-- explorer.lua
-- File explorer keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register explorer group with the main keymaps module
    keymaps.register_group("e", keymaps.group_icons.explorer .. " Explorer", {
        {
            key = "e",
            desc = "Toggle Explorer",
            neovim_cmd = "<cmd>Neotree toggle<CR>",
            vscode_cmd = "workbench.view.explorer"
        },
        {
            key = "o",
            desc = "Open Oil",
            neovim_cmd = "<cmd>Oil<CR>",
            vscode_cmd = "workbench.explorer.fileView.focus"
        }
    })
end

-- Add any explorer-specific plugins here
M.plugins = {}

return M