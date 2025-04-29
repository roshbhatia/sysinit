local M = {}

M.plugins = {{
    "zaldih/themery.nvim",
    lazy = false,
    priority = 999,
    config = function()
        require("themery").setup({
            themes = {{
                name = "Nordfox",
                colorscheme = "nordfox",
                before = [[
                        vim.g.nightfox_style = "nordfox"
                    ]]
            }, {
                name = "Tokyonight",
                colorscheme = "tokyonight"
            }, {
                name = "Catppuccin",
                colorscheme = "catppuccin"
            }, {
                name = "Ayu Dark",
                colorscheme = "ayu",
                before = [[
                        vim.g.ayucolor = "dark"
                    ]]
            }, {
                name = "Kanagawa",
                colorscheme = "kanagawa"
            }, {
                name = "Sonokai",
                colorscheme = "sonokai"
            }, {
                name = "Edge",
                colorscheme = "edge"
            }, {
                name = "Everforest",
                colorscheme = "everforest"
            }, {
                name = "Material",
                colorscheme = "material"
            }, {
                name = "Onedark",
                colorscheme = "onedark"
            }, {
                name = "Tokyodark",
                colorscheme = "tokyodark"
            }, {
                name = "Github",
                colorscheme = "github-theme"
            }, {
                name = "Rosepine",
                colorscheme = "rose-pine"
            }, {
                name = "Oxocarbon",
                colorscheme = "oxocarbon"
            }, {
                name = "Nightfly",
                colorscheme = "nightfly"
            }, {
                name = "Onedarkpro",
                colorscheme = "onedarkpro"
            }, {
                name = "Neon",
                colorscheme = "neon"
            }, {
                name = "Dracula",
                colorscheme = "dracula"
            }, {
                name = "Onenord",
                colorscheme = "onenord"
            }},
            livePreview = true,
            themeConfigFile = vim.fn.stdpath("config") .. "/lua/theme.lua",

            globalBefore = [[
                vim.opt.termguicolors = true
            ]],

            globalAfter = [[
                vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
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
