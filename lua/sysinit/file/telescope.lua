local M = {}

M.plugins = {{
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        {"nvim-telescope/telescope-fzf-native.nvim", build = "make"},
        "nvim-telescope/telescope-file-browser.nvim",
    },
    lazy = false,
    config = function()
        -- Telescope configuration
        
        -- Setup keybindings
        local wf = require("sysinit.keymaps.wf")
        wf.register_keymaps("<leader>f", "Find", {
            {"f", "<cmd>Telescope find_files<cr>", "Find Files"},
            {"g", "<cmd>Telescope live_grep<cr>", "Live Grep"},
            {"b", "<cmd>Telescope buffers<cr>", "Buffers"},
            {"h", "<cmd>Telescope help_tags<cr>", "Help Tags"},
            {"r", "<cmd>Telescope oldfiles<cr>", "Recent Files"},
            {"e", "<cmd>Telescope file_browser<cr>", "File Browser"},
        })
    end
}}

return M