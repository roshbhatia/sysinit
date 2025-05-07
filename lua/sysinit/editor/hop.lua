local M = {}

M.plugins = {{
    "smoka7/hop.nvim",
    version = "*",
    lazy = true,
    config = function()
        -- Hop configuration
        require("hop").setup()
        
        -- Setup keybindings
        vim.keymap.set("n", "s", "<cmd>HopChar2<cr>", { desc = "Hop to 2 chars" })
        vim.keymap.set("n", "S", "<cmd>HopWord<cr>", { desc = "Hop to word" })
    end
}}

return M