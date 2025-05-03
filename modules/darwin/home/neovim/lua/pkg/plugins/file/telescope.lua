-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-telescope/telescope.nvim/refs/heads/master/doc/telescope.txt"
local M = {}

M.plugins = {{
    "nvim-telescope/telescope.nvim",
    lazy = true,
    dependencies = {"nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons"},
    opts = {
        defaults = {
            prompt_prefix = "󱄅 ",
            selection_caret = "󱞩 ",
            path_display = {"smart"},
            sorting_strategy = "ascending"
        },
        pickers = {
            find_files = {
                hidden = true,
                find_command = {"fd", "--type", "f", "--strip-cwd-prefix"}
            }
        }
    }
}}

return M
