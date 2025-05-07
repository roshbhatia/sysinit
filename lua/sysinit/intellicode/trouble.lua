local M = {}

M.plugins = {{
    "folke/trouble.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    lazy = true,
    config = function()
        -- Trouble configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>x", "Diagnostics", {
            {"x", "<cmd>TroubleToggle<cr>", "Toggle Trouble"},
            {"w", "<cmd>TroubleToggle workspace_diagnostics<cr>", "Workspace Diagnostics"},
            {"d", "<cmd>TroubleToggle document_diagnostics<cr>", "Document Diagnostics"},
            {"q", "<cmd>TroubleToggle quickfix<cr>", "Quickfix List"},
        })
    end
}}

return M