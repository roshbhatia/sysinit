local M = {}

M.plugins = {{
    "zaldih/themery.nvim",
    lazy = false,
    priority = 999,
    dependencies = {"EdenEast/nightfox.nvim", "catppuccin/nvim", "folke/tokyonight.nvim", "lunarvim/darkplus.nvim",
                    "dracula/vim", "sainnhe/edge", "sainnhe/gruvbox-material", "navarasu/onedark.nvim",
                    "marko-cerovac/material.nvim"},
    config = function()
        require("themery").setup({
            themes = {{
                name = "Gruvbox Dark",
                colorscheme = "gruvbox",
                before = [[
                    vim.o.background = "dark"
                ]]
            }, {
                name = "Tokyonight Storm",
                colorscheme = "tokyonight",
                before = [[
                    vim.g.tokyonight_style = "storm"
                ]]
            }, {
                name = "Tokyonight Night",
                colorscheme = "tokyonight",
                before = [[
                    vim.g.tokyonight_style = "night"
                ]]
            }, {
                name = "Catppuccin Mocha",
                colorscheme = "catppuccin",
                before = [[
                    vim.g.catppuccin_flavour = "mocha"
                ]]
            }, {
                name = "Nightfox",
                colorscheme = "nightfox"
            }, {
                name = "Nordfox",
                colorscheme = "nordfox"
            }, {
                name = "Carbonfox",
                colorscheme = "carbonfox"
            }, {
                name = "Duskfox",
                colorscheme = "duskfox"
            }, {
                name = "Terafox",
                colorscheme = "terafox"
            }, {
                name = "Kanagawa Dragon",
                colorscheme = "kanagawa",
                before = [[
                    vim.g.kanagawa_theme_style = "dragon"
                ]]
            }, {
                name = "Kanagawa Wave",
                colorscheme = "kanagawa",
                before = [[
                    vim.g.kanagawa_theme_style = "wave"
                ]]
            }, {
                name = "Dracula",
                colorscheme = "dracula"
            }, {
                name = "GitHub Dark",
                colorscheme = "github-theme",
                before = [[
                    vim.g.github_dark_theme_style = "dark"
                ]]
            }, {
                name = "Oceanic Next",
                colorscheme = "OceanicNext"
            }, {
                name = "Nord",
                colorscheme = "nord"
            }, {
                name = "Onedark Deep",
                colorscheme = "onedark",
                before = [[
                    vim.g.onedark_style = "deep"
                ]]
            }, {
                name = "Material Deep Ocean",
                colorscheme = "material",
                before = [[
                    vim.g.material_style = "deep-ocean"
                ]]
            }, {
                name = "Moonfly",
                colorscheme = "moonfly"
            }, {
                name = "Substrata",
                colorscheme = "substrata"
            }, {
                name = "Edge Dark",
                colorscheme = "edge",
                before = [[
                    vim.g.edge_style = "neon"
                ]]
            }, {
                name = "Doom One",
                colorscheme = "doom-one"
            }},
            livePreview = true,
            globalBefore = [[
                vim.opt.termguicolors = true
            ]]
        })

        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
                local themery = require("themery")
                local current = themery.getCurrentTheme()

                if not current then
                    themery.setThemeByName("Nordfox", true)
                end
            end,
            once = true
        })
    end
}}

return M
