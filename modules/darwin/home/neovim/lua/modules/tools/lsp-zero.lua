-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/VonHeikemen/lsp-zero.nvim/v3.x/doc/md/lsp-zero.md"
local M = {}

M.plugins = {{
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {"neovim/nvim-lspconfig", "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim",
                    "hrsh7th/nvim-cmp", "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path",
                    "hrsh7th/cmp-cmdline", "saadparwaiz1/cmp_luasnip", "L3MON4D3/LuaSnip", -- Additional LSP plugins
    "b0o/schemastore.nvim", "folke/neodev.nvim"},
    config = function()
        local lsp_zero = require('lsp-zero')
        local lspconfig = require('lspconfig')
        local mason_lspconfig = require('mason-lspconfig')
        local neodev = require('neodev')
        local wk = require('which-key')

        neodev.setup({})

        lsp_zero.preset({
            name = 'recommended',
            set_lsp_keymaps = true,
            manage_nvim_cmp = false,
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

        mason_lspconfig.setup({
            ensure_installed = {"awk_ls", "bashls", "dagger", "docker_compose_language_service", "dockerls",
                                "golangci_lint_ls", "gopls", "grammarly", "helm-ls", "html", "jqls", "marksman",
                                "nil_ls", "spectral", "terraformls", "tflint", "ts_ls"},
            automatic_installation = true
        })
        mason_lspconfig.setup_handlers({lsp_zero.default_setup})

        vim.diagnostic.config({
            virtual_text = {
                prefix = '●',
                source = 'if_many'
            },
            float = {
                border = 'rounded',
                source = 'always'
            },
            severity_sort = true,
            update_in_insert = false
        })

    end
}}

return M
