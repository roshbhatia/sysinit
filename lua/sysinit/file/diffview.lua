local M = {}

M.plugins = {{
    "sindrets/diffview.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    lazy = true,
    config = function()
        -- Diffview configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>gd", "Git Diff", {
            {"o", "<cmd>DiffviewOpen<cr>", "Open Diffview"},
            {"c", "<cmd>DiffviewClose<cr>", "Close Diffview"},
            {"h", "<cmd>DiffviewFileHistory<cr>", "File History"},
        })
    end
}}

return M