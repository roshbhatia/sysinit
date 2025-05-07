local M = {}

M.plugins = {{
    "tpope/vim-fugitive",
    dependencies = {
        "tpope/vim-rhubarb", -- GitHub integration
    },
    lazy = true,
    config = function()
        -- Fugitive configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>g", "Git", {
            {"g", "<cmd>Git<cr>", "Status"},
            {"c", "<cmd>Git commit<cr>", "Commit"},
            {"p", "<cmd>Git push<cr>", "Push"},
            {"l", "<cmd>Git log<cr>", "Log"},
            {"b", "<cmd>Git blame<cr>", "Blame"},
            {"d", "<cmd>Gdiffsplit<cr>", "Diff"},
            {"h", "<cmd>GBrowse<cr>", "Open in GitHub"},
        })
    end
}}

return M