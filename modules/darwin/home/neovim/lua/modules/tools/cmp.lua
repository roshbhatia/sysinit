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
}, {
    "hrsh7th/nvim-cmp",
    lazy = false,
    dependencies = {"hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline",
                    "saadparwaiz1/cmp_luasnip", "L3MON4D3/LuaSnip", "onsails/lspkind.nvim",
                    "rafamadriz/friendly-snippets"},
    config = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')
        local lspkind = require('lspkind')

        require("luasnip.loaders.from_vscode").lazy_load()

        local has_words_before = function()
            if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
                return false
            end
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
        end

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end
            },
            window = {
                completion = cmp.config.window.bordered({
                    border = "rounded",
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None"
                }),
                documentation = cmp.config.window.bordered({
                    border = "rounded",
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None"
                })
            },
            formatting = {
                format = lspkind.cmp_format({
                    mode = 'symbol_text',
                    maxwidth = 50,
                    ellipsis_char = '...',
                    menu = {
                        buffer = "[Buffer]",
                        nvim_lsp = "[LSP]",
                        luasnip = "[Snippet]",
                        path = "[Path]",
                        copilot = "[Copilot]"
                    },
                    before = function(entry, vim_item)
                        vim_item.abbr = string.sub(vim_item.abbr, 1, 50)
                        return vim_item
                    end
                })
            },
            sources = cmp.config.sources({{
                name = 'copilot',
                group_index = 1
            }, {
                name = 'nvim_lsp',
                group_index = 2
            }, {
                name = 'luasnip',
                group_index = 2
            }, {
                name = 'path',
                group_index = 3
            }, {
                name = 'buffer',
                group_index = 3,
                keyword_length = 3
            }}),
            mapping = cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({
                    select = true
                }),
                ['<Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    elseif has_words_before() then
                        cmp.complete()
                    else
                        fallback()
                    end
                end, {'i', 's'}),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, {'i', 's'})
            }),
            experimental = {
                ghost_text = true
            },
            sorting = {
                priority_weight = 2,
                comparators = {require("copilot_cmp.comparators").prioritize, cmp.config.compare.offset,
                               cmp.config.compare.exact, cmp.config.compare.score, cmp.config.compare.recently_used,
                               cmp.config.compare.locality, cmp.config.compare.kind, cmp.config.compare.sort_text,
                               cmp.config.compare.length, cmp.config.compare.order}
            }
        })

        cmp.setup.filetype('gitcommit', {
            sources = cmp.config.sources({{
                name = 'buffer'
            }})
        })

        cmp.setup.cmdline({'/', '?'}, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {{
                name = 'buffer'
            }}
        })

        cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({{
                name = 'path'
            }}, {{
                name = 'cmdline'
            }})
        })
    end
}, {
    "zbirenbaum/copilot.lua",
    lazy = false,
    dependencies = {},
    config = function()
        require("copilot").setup({
            suggestion = {
                enabled = true
            },
            panel = {
                enabled = true
            },
            filetypes = {
                ["*"] = true,
                ["help"] = false,
                ["gitcommit"] = false,
                ["gitrebase"] = false,
                ["hgcommit"] = false,
                ["svn"] = false,
                ["cvs"] = false
            }
        })

        vim.g.copilot_filetypes = {
            ["*"] = true,
            ["markdown"] = true,
            ["yaml"] = true,
            ["help"] = false,
            ["gitrebase"] = false,
            ["hgcommit"] = false,
            ["svn"] = false,
            ["cvs"] = false
        }

        vim.api.nvim_create_autocmd("ColorScheme", {
            pattern = "*",
            callback = function()
                vim.api.nvim_set_hl(0, "CopilotSuggestion", {
                    fg = "#888888",
                    ctermfg = 8,
                    force = true
                })
            end
        })
        vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {
            fg = "#888888"
        })
    end
}, {
    "zbirenbaum/copilot-cmp",
    lazy = false,
    dependencies = {"zbirenbaum/copilot.lua", "hrsh7th/nvim-cmp"},
    config = function()
        require("copilot_cmp").setup({
            event = {"InsertEnter", "LspAttach"},
            fix_pairs = true
        })
    end
}, {
    "CopilotC-Nvim/CopilotChat.nvim",
    lazy = false,
    dependencies = {"nvim-lua/plenary.nvim", "zbirenbaum/copilot.lua"},
    config = function()
        require("CopilotChat").setup({
            model = "copilot:claude-3.5-sonnet",
            agent = "copilot",
            auto_insert_mode = false,
            system_prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nImplement a new feature based on the context and description below.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring multiple angles and approaches. You MUST break down the solution into clear steps within <step> tags. You SHALL start with a 20-step budget, requesting more for complex problems if needed. You MUST use <count> tags after each step to show the remaining budget. You SHALL stop when reaching 0. You MUST continuously adjust your reasoning based on intermediate results and reflections, adapting your strategy as you progress. You SHALL regularly evaluate progress using <reflection> tags. You MUST be critical and honest about your reasoning process. You SHALL assign a quality score between 0.0 and 1.0 using <reward> tags after each reflection. You MUST use this to guide your approach:\n0.8+: Continue current approach\n0.5-0.7: Consider minor adjustments\nBelow 0.5: Seriously consider backtracking and trying a different approach\nIf unsure or if reward score is low, you SHOULD backtrack and try a different approach, explaining your decision within <thinking> tags. For mathematical problems, you MUST show all work explicitly using LaTeX for formal notation and provide detailed proofs. You SHOULD explore multiple solutions individually if possible, comparing approaches in reflections. You SHALL use thoughts as a scratchpad, writing out all calculations and reasoning explicitly. You MUST synthesize the final answer within <answer> tags, providing a clear, concise summary. You SHALL conclude with a final reflection on the overall solution, discussing effectiveness, challenges, and solutions. You MUST assign a final reward score.",
            prompts = {
                Optimize = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nOptimize the selected code for improved performance and readability.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, analyzing performance bottlenecks and readability issues. You MUST break down the optimization process into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate progress using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the optimized code and explanation within <answer> tags."
                },
                Tests = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nGenerate comprehensive tests for the selected code.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring various testing approaches and edge cases. You MUST structure the test creation process in clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate progress using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final test suite within <answer> tags."
                },
                Review = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nConduct a thorough code review of the selected code, focusing on security, efficiency, and best practices.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, examining multiple aspects of code quality. You MUST break down the review into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate your findings using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final code review within <answer> tags.",
                    system_prompt = 'COPILOT_REVIEW'
                },
                Docs = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nGenerate comprehensive documentation for the selected code, including function descriptions, parameters, return values, and examples.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring how to best document each component. You MUST structure the documentation process within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate the quality of documentation using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final documentation within <answer> tags."
                },
                RefactorCode = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nRefactor the selected code to improve its structure while maintaining functionality.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring refactoring patterns and approaches. You MUST break down the refactoring process into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate progress using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the refactored code and explanation within <answer> tags."
                },
                Explain = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nExplain the programming concept demonstrated in the selected code in depth, with examples and analogies.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring different ways to explain the concept. You MUST structure your explanation in clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate the clarity of your explanation using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final concept explanation within <answer> tags.",
                    system_prompt = 'COPILOT_EXPLAIN'
                },
                Commit = {
                    prompt = 'Write commit message for the change with commitizen convention. Keep the title under 50 characters and wrap message at 72 characters. Format as a gitcommit code block.',
                    context = 'git:staged'
                }
            }
        })
    end
}}

return M
