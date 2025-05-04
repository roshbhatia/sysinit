local M = {}

M.plugins = {{
    "VonHeikemen/lsp-zero.nvim",
    lazy = false,
    branch = "v3.x",
    dependencies = {"neovim/nvim-lspconfig", "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim"}
}}

return M
