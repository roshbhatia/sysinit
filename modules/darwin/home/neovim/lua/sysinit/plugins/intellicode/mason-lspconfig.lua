local M = {}

M.plugins = {{
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {"williamboman/mason.nvim"},
    opts = {
        ensure_installed = {"bashls", "dagger", "docker_compose_language_service", "dockerls", "golangci_lint_ls",
                            "gopls", "helm_ls", "html", "jqls", "jsonls", "lua_ls", "marksman", "nil_ls", "pyright",
                            "terraformls", "tflint", "ts_ls", "vimls", "yamlls"},
        automatic_installation = true
    }
}}

return M
