local M = {}

M.plugins = {{
    "rmagatti/auto-session",
    lazy = true,
    config = function()
        -- Session configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>fs", "Session", {
            {"s", "<cmd>SessionSave<cr>", "Save Session"},
            {"l", "<cmd>SessionLoad<cr>", "Load Session"},
            {"d", "<cmd>SessionDelete<cr>", "Delete Session"},
        })
    end
}}

return M