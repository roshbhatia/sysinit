-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-telescope/telescope.nvim/refs/heads/master/doc/telescope.txt"
local plugin_spec = {}

M.plugins = {{
    "nvim-telescope/telescope.nvim",
    lazy = true,
    priority = 1000,
    dependencies = {"nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons"},
    config = function()
        require("telescope").setup({
            defaults = {
                prompt_prefix = "󱄅 ",
                selection_caret = "󱞩 ",
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
            }
        })
    end
}}

return plugin_spec
