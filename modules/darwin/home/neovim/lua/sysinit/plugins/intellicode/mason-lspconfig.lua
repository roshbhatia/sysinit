local M = {}

M.plugins = {{
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {"williamboman/mason.nvim"},
    opts = {
        ensure_installed = {"bashls", "dagger", "docker_compose_language_service", "dockerls", "golangci_lint_ls",
                            "gopls", "helm_ls", "html", "jqls", "jsonls" ,"lua_ls", "marksman", "terraformls", "tflint", "ts_ls", "yamllint"},
        automatic_installation = true,
        handlers = {function(server_name)
            require('lspconfig')[server_name].setup({})
        end}
    }
}}

return M
