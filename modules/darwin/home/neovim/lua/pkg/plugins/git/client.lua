-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/kdheepak/lazygit.nvim/refs/heads/main/README.md"
-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/lewis6991/gitsigns.nvim/refs/heads/main/doc/gitsigns.txt"
-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/tpope/vim-fugitive/refs/heads/master/doc/fugitive.txt"
local plugin_spec = {}

M.plugins = {{
    "folke/snacks.nvim",
    event = "VeryLazy",
    dependencies = {"nvim-lua/plenary.nvim", "lewis6991/gitsigns.nvim", "tpope/vim-fugitive",
                    "nvim-telescope/telescope.nvim"},
    opts = {
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
    },
    config = function()
        require("gitsigns").setup()
    end
}}

return plugin_spec
