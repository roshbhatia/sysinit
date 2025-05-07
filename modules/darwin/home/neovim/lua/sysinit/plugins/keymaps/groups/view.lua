-- view.lua
-- View operation keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register view group with the main keymaps module
    keymaps.register_group("v", keymaps.group_icons.view .. " View", {
        {
            key = "e",
            desc = "Toggle Explorer",
            neovim_cmd = "<cmd>NvimTreeToggle<CR>",
            vscode_cmd = "workbench.action.toggleSidebarVisibility"
        },
        {
            key = "p",
            desc = "Toggle Panel",
            neovim_cmd = "<cmd>lua require('toggleterm').toggle()<CR>",
            vscode_cmd = "workbench.action.togglePanel"
        }
    })
end

-- Add any view-specific plugins here
M.plugins = {}

return M