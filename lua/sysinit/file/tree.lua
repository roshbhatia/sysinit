local M = {}

M.plugins = {{
    "nvim-tree/nvim-tree.lua",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    config = function()
        -- NvimTree configuration
        
        -- Setup keybindings
        vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "[Explorer] Toggle File Explorer" })
    end
}}

return M