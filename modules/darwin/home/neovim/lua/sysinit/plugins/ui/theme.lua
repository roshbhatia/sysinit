local M = {}

M.plugins = {{"folke/tokyonight.nvim"}, {"AlexvZyl/nordic.nvim"}, {"EdenEast/nightfox.nvim"}, {"shaunsingh/nord.nvim"},
             {"marko-cerovac/material.nvim"}, {
    "zaldih/themery.nvim",
    lazy = false,
    config = function()
        require("themery").setup({
            themes = {"tokyonight", "nordic", "nightfox", "nord", "material"},
            livePreview = true
        })
    end
}}

return M
