-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/stevearc/oil.nvim/refs/heads/master/doc/api.md"
local M = {}

M.plugins = {{
    "stevearc/oil.nvim",
    commit = "685cdb4ffa74473d75a1b97451f8654ceeab0f4a",
    lazy = true,
    priority = 900,
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        require("oil").setup({
            default_file_explorer = true,
            columns = {"icon", "size", "mtime"},
            view_options = {
                show_hidden = true,
                is_hidden_file = function(name)
                    return vim.startswith(name, ".")
                end
            },
            float = {
                border = "rounded",
                max_width = 80,
                max_height = 30
            }
        })

        vim.keymap.set("n", "-", "<CMD>Oil<CR>", {
            desc = "Open parent directory"
        })
    end
}}

return M
