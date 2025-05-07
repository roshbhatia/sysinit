local M = {}

M.plugins = {{
    "pwntester/octo.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    lazy = true,
    config = function()
        -- Octo configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>go", "Git Octo", {
            {"i", "<cmd>Octo issue list<cr>", "List Issues"},
            {"p", "<cmd>Octo pr list<cr>", "List PRs"},
            {"r", "<cmd>Octo repo list<cr>", "List Repos"},
        })
    end
}}

return M