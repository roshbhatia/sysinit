local M = {}

M.plugins = {{
    "pwntester/octo.nvim",
    lazy = false,
    dependencies = {"nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim"}
}}

return M
