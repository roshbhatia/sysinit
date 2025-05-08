local M = {}

M.plugins = {{
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {{
        "<leader>ff",
        "<cmd>Telescope find_files<cr>",
        desc = "Picker: find files"
    }, {
        "<leader>fg",
        "<cmd>Telescope live_grep<cr>",
        desc = "Picker: live grep"
    }, {
        "<leader>fb",
        "<cmd>Telescope buffers<cr>",
        desc = "Picker: find buffers"
    }, {
        "<leader>fh",
        "<cmd>Telescope help_tags<cr>",
        desc = "Picker: help tags"
    }, {
        "<leader><leader>",
        "<cmd>Telescope cmdline<cr>",
        desc = "Command Line"
    }},
    dependencies = {{
        'stevearc/overseer.nvim',
        opts = {},
        config = function()
            require("overseer").setup()
        end
    }, {"nvim-lua/plenary.nvim"}, {
        "nvim-tree/nvim-web-devicons",
        lazy = true
    }, {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make"
    }, 'jonarrien/telescope-cmdline.nvim'},
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")

        telescope.setup()

        telescope.load_extension("cmdline")

        vim.api.nvim_set_keymap('n', ':', ':Telescope cmdline<CR>', {
            noremap = true,
            desc = "Cmdline"
        })
    end
}}

return M
