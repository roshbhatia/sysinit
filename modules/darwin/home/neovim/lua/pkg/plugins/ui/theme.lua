local plugin_spec = {}

M.plugins = {{
    "zaldih/themery.nvim",
    lazy = false,
    priority = 999,
    dependencies = {"EdenEast/nightfox.nvim", "catppuccin/nvim", "folke/tokyonight.nvim", "lunarvim/darkplus.nvim",
                    "dracula/vim", "sainnhe/edge", "sainnhe/gruvbox-material", "navarasu/onedark.nvim",
                    "marko-cerovac/material.nvim"},
    config = function()
        require("themery").setup({
            themes = {"blue", "carbonfox", "catppuccin", "catppuccin-frappe", "catppuccin-latte",
                      "catppuccin-macchiato", "catppuccin-mocha", "darkblue", "darkplus", "dawnfox", "dayfox",
                      "default", "delek", "desert", "dracula", "duskfox", "edge", "elflord", "evening",
                      "gruvbox-material", "habamax", "industry", "koehler", "lunaperche", "material", "material-darker",
                      "material-deep-ocean", "material-lighter", "material-oceanic", "material-palenight", "morning",
                      "murphy", "nightfox", "nordfox", "onedark", "pablo", "peachpuff", "quiet", "retrobox", "ron",
                      "shine", "slate", "sorbet", "terafox", "tokyonight", "tokyonight-day", "tokyonight-moon",
                      "tokyonight-night", "tokyonight-storm", "torte", "unokai", "vim", "wildcharm", "zaibatsu",
                      "zellner"},
            livePreview = true
        })
    end
}}

return plugin_spec

