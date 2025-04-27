-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/VonHeikemen/lsp-zero.nvim/v3.x/doc/md/lsp-zero.md"
local M = {}

M.plugins = {{
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {"neovim/nvim-lspconfig", "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim"},
    config = function()
        require('lsp-zero').preset({
            name = 'recommended',
            set_lsp_keymaps = false,
            manage_nvim_cmp = true,
            suggest_lsp_servers = true
        })

        require('mason').setup({
            ui = {
                border = 'rounded',
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗"
                }
            }
        })

        require('mason-lspconfig').setup({
            ensure_installed = {"awk_ls", "bashls", "dagger", "docker_compose_language_service", "dockerls",
                                "golangci_lint_ls", "gopls", "grammarly", "helm_ls", "html", "jqls", "marksman",
                                "spectral", "terraformls", "tflint", "ts_ls"},
            automatic_installation = true,
            handlers = {function(server_name)
                require('lspconfig')[server_name].setup({})
            end}
        })
    end
}}

return M
