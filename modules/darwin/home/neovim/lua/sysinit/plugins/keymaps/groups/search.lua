-- search.lua
-- Search keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register search group with the main keymaps module
    keymaps.register_group("f", keymaps.group_icons.search .. " Search", {
        {
            key = "f",
            desc = "Find Files",
            neovim_cmd = "<cmd>Telescope find_files<CR>",
            vscode_cmd = "workbench.action.quickOpen"
        },
        {
            key = "g",
            desc = "Find in Files",
            neovim_cmd = "<cmd>Telescope live_grep<CR>",
            vscode_cmd = "workbench.action.findInFiles"
        },
        {
            key = "s",
            desc = "Find Symbol",
            neovim_cmd = "<cmd>Telescope lsp_document_symbols<CR>",
            vscode_cmd = "workbench.action.gotoSymbol"
        }
    })
end

-- Add any search-specific plugins here
M.plugins = {}

return M