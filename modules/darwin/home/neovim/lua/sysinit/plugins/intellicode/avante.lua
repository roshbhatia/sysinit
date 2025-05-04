local M = {}

M.plugins = {{
    "yetone/avante.nvim",
    dependencies = {"nvim-treesitter/nvim-treesitter", "stevearc/dressing.nvim", "nvim-lua/plenary.nvim",
                    "MunifTanjim/nui.nvim", "nvim-telescope/telescope.nvim", "hrsh7th/nvim-cmp",
                    "nvim-tree/nvim-web-devicons", "zbirenbaum/copilot.lua"},
    lazy = true,
    cmd = "AvanteToggle",
    opts = {
        provider = "copilot",
        behaviour = {
            auto_suggestions = false,
            auto_set_highlight_group = true,
            auto_set_keymaps = true,
            minimize_diff = true,
            enable_token_counting = true,
            enable_cursor_planning_mode = true
        },
        windows = {
            position = "right",
            wrap = true,
            width = 30
        },
        mappings = {
            ask = "",
            edit = "",
            refresh = ""
        }
    }
}}

return M
