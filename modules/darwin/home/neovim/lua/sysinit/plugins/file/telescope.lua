local M = {}

M.plugins = {{
    "nvim-telescope/telescope.nvim",
    lazy = false,
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
        "<cmd>FineCmdline<cr>",
        desc = "Commandline"
    }},
    dependencies = {{
        'stevearc/overseer.nvim',
        opts = {},
        config = function()
            require("overseer").setup()
        end
    }, {
        'VonHeikemen/fine-cmdline.nvim',
        requires = {{'MunifTanjim/nui.nvim'}}
    }, "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "nvim-telescope/telescope-fzy-native.nvim",
                    'jonarrien/telescope-cmdline.nvim', "nvim-telescope/telescope-dap.nvim", "j-hui/fidget.nvim"},
    config = function()
        local telescope = require("telescope")

        telescope.setup({
            extensions = {
                fzy_native = {
                    override_generic_sorter = false,
                    override_file_sorter = true
                }
            }
        })

        telescope.load_extension('fzy_native')
        telescope.load_extension('dap')
        telescope.load_extension("fidget")

        vim.api.nvim_set_keymap('n', ':', '<cmd>FineCmdline<CR>', {
            noremap = true
        })
    end
}}

return M
