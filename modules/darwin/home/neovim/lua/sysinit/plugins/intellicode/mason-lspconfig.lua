local M = {}

M.plugins = {{
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {"williamboman/mason.nvim", "neovim/nvim-lspconfig", "VonHeikemen/lsp-zero.nvim"},
    opts = {
        ensure_installed = {"bashls", "dagger", "docker_compose_language_service", "dockerls", "golangci_lint_ls",
                            "gopls", "helm_ls", "html", "jqls", "marksman", "spectral", "terraformls", "tflint", "ts_ls"},
        automatic_installation = true,
        handlers = {function(server_name)
            require("lspconfig")[server_name].setup({
                capabilities = require("lsp-zero").get_capabilities()
            })
        end}
    }
}}

return M
