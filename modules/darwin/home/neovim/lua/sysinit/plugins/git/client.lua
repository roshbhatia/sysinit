-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/kdheepak/lazygit.nvim/refs/heads/main/README.md"
local M = {}

-- Solely used for lazygit
M.plugins = {{
    "folke/snacks.nvim",
    cmd = "LazyGit",
    lazy = true,
    event = "VeryLazy",
    dependencies = {"nvim-lua/plenary.nvim", "lewis6991/gitsigns.nvim", "tpope/vim-fugitive",
                    "nvim-telescope/telescope.nvim"},
    config = function()
        require("snacks").setup({
            lazygit = {},
            bigfile = {
                enabled = true
            },
            dashboard = {
                enabled = false
            },
            explorer = {
                enabled = false
            },
            indent = {
                enabled = false
            },
            input = {
                enabled = false
            },
            picker = {
                enabled = false
            },
            notifier = {
                enabled = false
            },
            quickfile = {
                enabled = false
            },
            scope = {
                enabled = false
            },
            scroll = {
                enabled = false
            },
            statuscolumn = {
                enabled = false
            },
            words = {
                enabled = false
            }
        })
        vim.api.nvim_create_user_command("LazyGit", function()
            require("snacks.lazygit").open()
        end, {})
    end
}}

return M
