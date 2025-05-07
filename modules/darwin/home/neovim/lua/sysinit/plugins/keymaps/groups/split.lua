-- split.lua
-- Window split keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register split group with the main keymaps module
    keymaps.register_group("p", keymaps.group_icons.split .. " Split", {
        {
            key = "v",
            desc = "Split Vertical",
            neovim_cmd = "<cmd>vsplit<CR>",
            vscode_cmd = "workbench.action.splitEditorRight"
        },
        {
            key = "h",
            desc = "Split Horizontal",
            neovim_cmd = "<cmd>split<CR>",
            vscode_cmd = "workbench.action.splitEditorDown"
        }
    })
end

-- Add any split-specific plugins here
M.plugins = {}

return M