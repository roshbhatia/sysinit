local M = {}

M.plugins = {{
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {"williamboman/mason.nvim", "WhoIsSethDaniel/mason-tool-installer.nvim"},
    config = function()
        require("mason-lspconfig").setup()
    end
}}

return M
