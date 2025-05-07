-- problems.lua
-- Problems/diagnostics keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register problems group with the main keymaps module
    keymaps.register_group("q", keymaps.group_icons.problems .. " Problems", {
        {
            key = "p",
            desc = "Show Problems",
            neovim_cmd = "<cmd>Telescope diagnostics<CR>",
            vscode_cmd = "workbench.actions.view.problems"
        }
    })
end

-- Add any problems-specific plugins here
M.plugins = {}

return M