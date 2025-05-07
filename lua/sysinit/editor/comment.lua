local M = {}

M.plugins = {{
    "numToStr/Comment.nvim",
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        -- Comment.nvim configuration
        require("Comment").setup()
        
        -- Standard vim-commentary style keymaps are handled by the plugin automatically
        -- gcc: Toggle comment for current line
        -- gbc: Toggle block comment for current line
        -- gc: Toggle comment for visual selection (visual mode)
        -- gb: Toggle block comment for visual selection (visual mode)
    end
}}

return M