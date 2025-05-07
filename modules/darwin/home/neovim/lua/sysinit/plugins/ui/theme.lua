local M = {}

M.plugins = {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd([[colorscheme tokyonight-night]])
        end
    },
    {
        "AlexvZyl/nordic.nvim",
        lazy = true,
        enabled = false
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        enabled = false
    },
    {
        "EdenEast/nightfox.nvim",
        lazy = true,
        enabled = false
    },
    {
        "shaunsingh/nord.nvim",
        lazy = true,
        enabled = false
    },
    {
        "marko-cerovac/material.nvim",
        lazy = true,
        enabled = false
    },
    {
        "themercorp/themer.lua",
        name = "themer",
        lazy = true,
        cmd = "Themery",
        config = function()
            require("themer").setup({
                colorscheme = "tokyonight-night",
                styles = {
                    functionStyle = {
                        italic = true,
                        bold = true
                    },
                    keywordStyle = {
                        italic = true
                    },
                    variableStyle = {
                        italic = false
                    },
                    commentStyle = {
                        italic = true
                    },
                    typeStyle = {
                        italic = true,
                        bold = true
                    }
                },
                plugins = {
                    treesitter = true,
                    indentline = true,
                    barbar = true,
                    bufferline = true,
                    cmp = true,
                    gitsigns = true,
                    lsp = true,
                    telescope = true
                }
            })
        end
    }
}

return M