local M = {}

M.plugins = {{
    "williamboman/mason.nvim",
    lazy = false,
    opts = {
        install_root_dir = vim.fn.stdpath("data") .. "/mason",
        ui = {
            border = "rounded",
            icons = {
                package_installed = "✓",
                package_pending = "➜",
                package_uninstalled = "✗"
            }
        }
    }
}}

return M
