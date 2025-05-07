-- fold.lua
-- Code folding keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register fold group with the main keymaps module
    keymaps.register_group("s", keymaps.group_icons.fold .. " Fold", {
        {
            key = "c",
            desc = "Close Fold",
            neovim_cmd = "zc",
            vscode_cmd = "editor.fold"
        },
        {
            key = "o",
            desc = "Open Fold",
            neovim_cmd = "zo",
            vscode_cmd = "editor.unfold"
        },
        {
            key = "t",
            desc = "Toggle Fold",
            neovim_cmd = "za",
            vscode_cmd = "editor.toggleFold"
        },
        {
            key = "a",
            desc = "Toggle All Folds",
            neovim_cmd = "zA",
            vscode_cmd = "editor.toggleAllFolds"
        }
    })
end

-- Add any fold-specific plugins here
M.plugins = {}

return M