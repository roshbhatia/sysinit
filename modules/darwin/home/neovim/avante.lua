local M = {}

M.plugins = {{
    "yetone/aider.nvim",
    version = false,
    dependencies = {"nvim-treesitter/nvim-treesitter", "stevearc/dressing.nvim", "nvim-lua/plenary.nvim",
                    "MunifTanjim/nui.nvim", "nvim-telescope/telescope.nvim", "hrsh7th/nvim-cmp",
                    "nvim-tree/nvim-web-devicons", "zbirenbaum/copilot.lua"},
    event = "VeryLazy",
    cmd = "aiderToggle",
    build = "make",
    opts = {
        provider = "copilot",
        behaviour = {
            auto_apply_diff_after_generation = true,
            auto_set_keymaps = false,
            enable_cursor_planning_mode = true,
            enable_token_counting = true
        },
        windows = {
            position = "right",
            wrap = true,
            width = 30
        },
        hints = {
            enabled = false
        }
    },
    config = function(_, opts)
        require("aider").setup(opts)
        vim.cmd("aiderBuild")
    end
}}

return M
