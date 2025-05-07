local M = {}

M.plugins = {{
    "akinsho/toggleterm.nvim",
    version = "*",
    lazy = true,
    config = function()
        -- Terminal configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>t", "Terminal", {
            {"t", "<cmd>ToggleTerm<cr>", "Toggle Terminal"},
            {"f", "<cmd>ToggleTerm direction=float<cr>", "Float Terminal"},
            {"h", "<cmd>ToggleTerm direction=horizontal<cr>", "Horizontal Terminal"},
            {"v", "<cmd>ToggleTerm direction=vertical<cr>", "Vertical Terminal"},
        })
    end
}}

return M