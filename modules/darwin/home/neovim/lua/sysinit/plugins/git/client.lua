-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/kdheepak/lazygit.nvim/refs/heads/main/README.md"
local M = {}

-- Solely used for lazygit
M.plugins = {{
    "folke/snacks.nvim",
    cmd = "LazyGit",
    lazy = false,
    priority = 1000,
    opts = {
        lazygit = {},
        bigfile = {
            enabled = false
        },
        dashboard = {
            enabled = false
        },
        explorer = {
            enabled = false
        },
        image = {
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
    config = function(_, opts)
        require("snacks").setup(opts)

        vim.api.nvim_create_user_command("LazyGit", function()
            require("snacks.lazygit").open()
        end, {})
    end
}}

return M
