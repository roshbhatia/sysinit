local plugin_spec = {}

M.plugins = {{
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {"neovim/nvim-lspconfig", "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim",
                    "folke/trouble.nvim", "nvim-tree/nvim-web-devicons"},
    config = function()
        local lsp = require('lsp-zero')
        lsp.preset({
            name = 'recommended',
            set_lsp_keymaps = false,
            manage_nvim_cmp = false,
            suggest_lsp_servers = true
        })

        require('mason').setup({
            install_root_dir = vim.fn.stdpath("data") .. "/mason",
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
            ensure_installed = {"bashls", "dagger", "docker_compose_language_service", "dockerls", "golangci_lint_ls",
                                "gopls", "helm_ls", "html", "jqls", "marksman", "spectral", "terraformls", "tflint",
                                "ts_ls"},
            automatic_installation = true,
            handlers = {function(server_name)
                require('lspconfig')[server_name].setup({
                    capabilities = lsp.get_capabilities()
                })
            end}
        })

        -- Setup Trouble for diagnostics display
        require("trouble").setup({
            position = "bottom",
            height = 10,
            width = 50,
            icons = true,
            mode = "workspace_diagnostics",
            auto_preview = true,
            auto_close = false,
            auto_open = false,
            auto_jump = false,
            use_diagnostic_signs = true,
            action_keys = {
                close = "q",
                cancel = "<esc>",
                refresh = "r",
                jump = {"<cr>", "<tab>"},
                open_split = {"<c-x>"},
                open_vsplit = {"<c-v>"},
                open_tab = {"<c-t>"},
                jump_close = {"o"},
                toggle_mode = "m",
                toggle_preview = "P",
                hover = "K",
                preview = "p",
                close_folds = {"zM", "zm"},
                open_folds = {"zR", "zr"},
                toggle_fold = {"zA", "za"},
                previous = "k",
                next = "j"
            },
            indent_lines = true,
            win_config = {
                border = "rounded"
            },
            auto_fold = false,
            signs = {
                error = "✗",
                warning = "⚠",
                hint = "➤",
                information = "ℹ",
                other = "➤"
            }
        })
    end
}}

return plugin_spec
