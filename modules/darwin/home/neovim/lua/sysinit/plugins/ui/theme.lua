local M = {}

M.plugins = {{
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd([[colorscheme tokyonight-night]])
    end
}, {
    "AlexvZyl/nordic.nvim",
    lazy = true,
    enabled = false
}, {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    enabled = false
}, {
    "EdenEast/nightfox.nvim",
    lazy = true,
    enabled = false
}, {
    "shaunsingh/nord.nvim",
    lazy = true,
    enabled = false
}, {
    "marko-cerovac/material.nvim",
    lazy = true,
    enabled = false
}, {
    "zaldih/themery.nvim",
    lazy = false,
    config = function()
        require("themery").setup({
            themes = {"tokyonight", "nordic", "catpuccin", "nightfox", "nord", "material"},
            livePreview = true
        })
    end
}}

return M
