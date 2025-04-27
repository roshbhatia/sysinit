-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/LmanTW/themify.nvim/refs/heads/main/documents/api.md"
local M = {}

M.plugins = {{
    "LmanTW/themify.nvim",
    lazy = false,
    priority = 999,
    config = function()
        require("themify").setup({
            async = true,
            activity = true,
            "EdenEast/nightfox.nvim",
            "RRethy/base16-nvim",
            "folke/tokyonight.nvim",
            "catppuccin/nvim",
            "Shatur/neovim-ayu",
            "rmehri01/onenord.nvim",
            "rebelot/kanagawa.nvim",
            "sainnhe/sonokai",
            "sainnhe/edge",
            "sainnhe/everforest",
            "marko-cerovac/material.nvim",
            "navarasu/onedark.nvim",
            "tiagovla/tokyodark.nvim",
            "projekt0n/github-nvim-theme",
            "rose-pine/neovim",
            "nyoom-engineering/oxocarbon.nvim",
            "folke/twilight.nvim",
            "LunarVim/horizon.nvim",
            "bluz71/vim-nightfly-colors",
            "olimorris/onedarkpro.nvim",
            "rafamadriz/neon",
            "dracula/vim",

            loader = function()
                local success = pcall(function()
                    require("themify").load_saved()
                end)
            end
        })
    end
}}

return M
