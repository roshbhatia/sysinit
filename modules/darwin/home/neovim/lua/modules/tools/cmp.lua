-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/hrsh7th/nvim-cmp/main/doc/cmp.txt"
local M = {}

M.plugins = {{
    "hrsh7th/nvim-cmp",
    lazy = false,
    dependencies = {"hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline",
                    "saadparwaiz1/cmp_luasnip", "L3MON4D3/LuaSnip", "onsails/lspkind.nvim",
                    "rafamadriz/friendly-snippets"},
    config = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')
        local lspkind = require('lspkind')

        -- Load friendly-snippets
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

                -- Tab for selection and navigation in the popup menu
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

        -- Set configuration for specific filetype.
        cmp.setup.filetype('gitcommit', {
            sources = cmp.config.sources({{
                name = 'buffer'
            }})
        })

        -- Use buffer source for `/` and `?`
        cmp.setup.cmdline({'/', '?'}, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {{
                name = 'buffer'
            }}
        })

        -- Use cmdline & path source for ':'
        cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({{
                name = 'path'
            }}, {{
                name = 'cmdline'
            }})
        })
    end
}}

return M
