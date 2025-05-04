local M = {}

M.plugins = { {
    "yetone/avante.nvim",
    version = false,
    dependencies = { "nvim-treesitter/nvim-treesitter", "stevearc/dressing.nvim", "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim", "nvim-telescope/telescope.nvim", "hrsh7th/nvim-cmp",
        "nvim-tree/nvim-web-devicons", "zbirenbaum/copilot.lua" },
    event = "VeryLazy",
    cmd = "AvanteToggle",
    build = "make",
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
            ask = "<leader>ua",     -- ask
            edit = "<leader>ue",    -- edit
            refresh = "<leader>ur", -- refresh
        }
    },
    config = function(_, opts)
        require("avante").setup(opts)
        vim.cmd("AvanteBuild")
    end
} }

return M
