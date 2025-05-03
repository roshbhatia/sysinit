local M = {}

M.plugins = {{
    "VonHeikemen/lsp-zero.nvim",
    lazy = false,
    dependencies = {"neovim/nvim-lspconfig", "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim"},
    config = function()
        local lsp = require("lsp-zero")
        lsp.preset({
            name = "recommended",
            set_lsp_keymaps = false,
            manage_nvim_cmp = false,
            suggest_lsp_servers = true
        })
    end
}}

return M
