local M = {}

M.plugins = {{
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "zbirenbaum/copilot.lua",
    },
    lazy = true,
    config = function()
        -- Copilot Chat configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>a", "AI", {
            {"c", "<cmd>CopilotChatToggle<cr>", "Toggle Chat"},
            {"p", "<cmd>CopilotChatOpen<cr>", "Open Chat Panel"},
            {"e", "<cmd>CopilotChatExplain<cr>", "Explain Code"},
        })
    end
}}

return M