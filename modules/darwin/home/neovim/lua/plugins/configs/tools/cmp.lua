local M = {}

M.plugins = {{
    "saghen/blink.cmp",
    version = "1.*",
    lazy = false,
    dependencies = {"rafamadriz/friendly-snippets", "L3MON4D3/LuaSnip", "folke/trouble.nvim",
                    "nvim-tree/nvim-web-devicons", "pta2002/intellitab.nvim", "neovim/nvim-lspconfig",
                    "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim"},
    config = function()
        -- Setup Mason
        require('mason').setup({
            install_root_dir = (os.getenv("XDG_DATA_HOME") or os.getenv("HOME") .. "/.local/share") .. "/nvim/mason",
            ui = {
                border = 'rounded',
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗"
                }
            }
        })

        vim.cmd("MasonUpdate")

        -- Setup LSP
        local lsp_servers = {"awk_ls", "bashls", "dagger", "docker_compose_language_service", "dockerls",
                             "golangci_lint_ls", "gopls", "grammarly", "helm_ls", "html", "jqls", "marksman",
                             "spectral", "terraformls", "tflint", "ts_ls"}

        require('mason-lspconfig').setup({
            ensure_installed = lsp_servers,
            automatic_installation = true
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

        -- Get LSP capabilities from blink.cmp
        local capabilities = require("blink.cmp").get_lsp_capabilities()

        -- Setup each LSP server
        for _, server_name in ipairs(lsp_servers) do
            require('lspconfig')[server_name].setup({
                capabilities = capabilities
            })
        end

        -- Setup blink.cmp
        require("blink.cmp").setup({
            -- Explicitly disable native copilot suggestion display
            snippets = {
                preset = 'luasnip'
            },

            -- Enable signature help
            signature = {
                enabled = true,
                window = {
                    border = 'rounded',
                    winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder'
                }
            },

            -- Completion configuration
            completion = {
                menu = {
                    border = 'rounded',
                    winblend = 0,
                    winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
                    draw = {
                        -- Match the previous nvim-cmp style
                        columns = {{"kind_icon"}, {
                            "label",
                            "label_description",
                            gap = 1
                        }},
                        components = {
                            kind_icon = {
                                text = function(ctx)
                                    return ctx.kind_icon .. ctx.icon_gap
                                end,
                                highlight = function(ctx)
                                    return {{
                                        group = ctx.kind_hl,
                                        priority = 20000
                                    }}
                                end
                            }
                        }
                    }
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 500,
                    window = {
                        border = 'rounded',
                        winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder'
                    }
                },
                ghost_text = {
                    enabled = true
                },
                list = {
                    selection = {
                        preselect = true,
                        auto_insert = true
                    }
                }
            },

            -- Keymaps
            keymap = {
                preset = 'default',
                ['<Tab>'] = {function(cmp)
                    if cmp.snippet_active({
                        direction = 1
                    }) then
                        return cmp.snippet_forward()
                    elseif cmp.visible() then
                        return cmp.select_next()
                    else
                        return require("intellitab").indent()
                    end
                end},
                ['<S-Tab>'] = {function(cmp)
                    if cmp.visible() then
                        return cmp.select_prev()
                    else
                        return cmp.complete()
                    end
                end},
                ['<CR>'] = {'accept'},
                ['<C-space>'] = {'show', 'show_documentation'},
                ['<C-e>'] = {'cancel'},
                ['<C-b>'] = {'scroll_documentation_up'},
                ['<C-f>'] = {'scroll_documentation_down'},
                ['<C-n>'] = {'select_next'},
                ['<C-p>'] = {'select_prev'}
            },

            -- Sources configuration
            sources = {
                default = {'lsp', 'path', 'snippets', 'buffer'},
                providers = {
                    lsp = {
                        name = 'LSP',
                        transform_items = function(_, items)
                            return vim.tbl_filter(function(item)
                                return item.kind ~= require('blink.cmp.types').CompletionItemKind.Text
                            end, items)
                        end
                    },
                    buffer = {
                        name = 'Buffer',
                        score_offset = -3
                    },
                    path = {
                        name = 'Path',
                        score_offset = 3
                    },
                    snippets = {
                        name = 'Snippets',
                        score_offset = -1
                    }
                }
            },

            -- Appearance settings
            appearance = {
                nerd_font_variant = 'mono',
                kind_icons = {
                    Text = '󰉿',
                    Method = '󰊕',
                    Function = '󰊕',
                    Constructor = '󰒓',
                    Field = '󰜢',
                    Variable = '󰆦',
                    Class = '󱡠',
                    Interface = '󱡠',
                    Module = '󰅩',
                    Property = '󰖷',
                    Unit = '󰪚',
                    Value = '󰦨',
                    Enum = '󰦨',
                    Keyword = '󰻾',
                    Snippet = '󱄽',
                    Color = '󰏘',
                    File = '󰈔',
                    Reference = '󰬲',
                    Folder = '󰉋',
                    EnumMember = '󰦨',
                    Constant = '󰏿',
                    Struct = '󱡠',
                    Event = '󱐋',
                    Operator = '󰪚',
                    TypeParameter = '󰬛'
                }
            },

            -- Use rust implementation for fuzzy matching if available
            fuzzy = {
                implementation = "prefer_rust"
            }
        })

        -- Set up auto-commands to manage Copilot
        local function hide_copilot()
            if vim.g.copilot_enabled == true then
                vim.b.copilot_suggestion_hidden = true
            end
        end

        local function show_copilot()
            if vim.g.copilot_enabled == true then
                vim.b.copilot_suggestion_hidden = false
            end
        end

        vim.api.nvim_create_autocmd('User', {
            pattern = 'BlinkCmpMenuOpen',
            callback = hide_copilot
        })

        vim.api.nvim_create_autocmd('User', {
            pattern = 'BlinkCmpMenuClose',
            callback = show_copilot
        })
    end
}}

return M
