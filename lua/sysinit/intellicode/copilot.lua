local M = {}

M.plugins = {{
    "zbirenbaum/copilot.lua",
    lazy = true,
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
        -- Copilot configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>a", "AI", {
            {"e", "<cmd>Copilot enable<cr>", "Enable Copilot"},
            {"d", "<cmd>Copilot disable<cr>", "Disable Copilot"},
            {"s", "<cmd>Copilot suggestion<cr>", "Trigger Suggestion"},
        })
    end
}}

return M