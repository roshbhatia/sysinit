-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-telescope/telescope.nvim/refs/heads/master/doc/telescope.txt"
local M = {}

M.plugins = {{
    "nvim-telescope/telescope.nvim",
    commit = "a4ed82509cecc56df1c7138920a1aeaf246c0ac5",
    lazy = true,
    priority = 1000,
    dependencies = {"nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "barrett-ruth/http-codes.nvim"},
    config = function()
        require("telescope").setup({
            defaults = {
                prompt_prefix = ">",
                selection_caret = "=>",
                path_display = {"smart"},
                sorting_strategy = "ascending",
                layout_config = {
                    horizontal = {
                        prompt_position = "top",
                        preview_width = 0.55,
                        results_width = 0.8
                    },
                    vertical = {
                        mirror = false
                    },
                    width = 0.87,
                    height = 0.80,
                    preview_cutoff = 120
                },
                file_previewer = require("telescope.previewers").vim_buffer_cat.new,
                grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
                qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
                buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker
            },
            pickers = {
                find_files = {
                    hidden = true,
                    find_command = {"fd", "--type", "f", "--strip-cwd-prefix"}
                }
            },
            extensions = {
                ["http-codes"] = {
                    open_url = nil,
                    telescope_opts = {}
                }
            }
        })

        require('telescope').load_extension('http-codes')
    end
}, {
    "barrett-ruth/http-codes.nvim",
    lazy = true,
    config = true
}}

return M
