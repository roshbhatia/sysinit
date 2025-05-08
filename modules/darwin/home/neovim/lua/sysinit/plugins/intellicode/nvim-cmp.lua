local M = {}

M.plugins = {{
    "hrsh7th/nvim-cmp",
    event = {"InsertEnter", "CmdlineEnter"},
    dependencies = {"L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path",
                    "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-nvim-lua", "hrsh7th/cmp-cmdline", "onsails/lspkind.nvim"},
    config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")

        -- Helper functions
        local has_words_before = function()
            unpack = unpack or table.unpack
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
        end

        local function border(hl_name)
            return {{"╭", hl_name}, {"─", hl_name}, {"╮", hl_name}, {"│", hl_name}, {"╯", hl_name},
                    {"─", hl_name}, {"╰", hl_name}, {"│", hl_name}}
        end

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end
            },
            window = {
                completion = {
                    border = border("CmpBorder"),
                    winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None",
                    scrollbar = true
                },
                documentation = {
                    border = border("CmpDocBorder"),
                    winhighlight = "Normal:CmpDoc"
                }
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-k>"] = cmp.mapping.select_prev_item(),
                ["<C-j>"] = cmp.mapping.select_next_item(),
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete({}),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<CR>"] = cmp.mapping.confirm({
                    select = false
                }),
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    elseif has_words_before() then
                        cmp.complete()
                    else
                        fallback()
                    end
                end, {"i", "s"}),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, {"i", "s"})
            }),
            formatting = {
                format = lspkind.cmp_format({
                    mode = "symbol_text",
                    maxwidth = 50,
                    ellipsis_char = "...",
                    menu = {
                        buffer = "[Buffer]",
                        nvim_lsp = "[LSP]",
                        luasnip = "[Snippet]",
                        nvim_lua = "[Lua]",
                        path = "[Path]",
                        copilot = "[Copilot]"
                    }
                })
            },
            sources = {{
                name = "copilot",
                group_index = 2,
                priority = 100
            }, {
                name = "nvim_lsp",
                group_index = 2,
                priority = 90
            }, {
                name = "luasnip",
                group_index = 2,
                priority = 80
            }, {
                name = "buffer",
                group_index = 2,
                priority = 70
            }, {
                name = "nvim_lua",
                group_index = 2,
                priority = 60
            }, {
                name = "path",
                group_index = 2,
                priority = 50
            }},
            sorting = {
                priority_weight = 2,
                comparators = { -- Below is the default comparitor list and order for nvim-cmp
                cmp.config.compare.offset, -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
                cmp.config.compare.exact, cmp.config.compare.score, cmp.config.compare.recently_used,
                cmp.config.compare.locality, cmp.config.compare.kind, cmp.config.compare.sort_text,
                cmp.config.compare.length, cmp.config.compare.order}
            },
            experimental = {
                ghost_text = false
            }
        })

        -- Set up special configuration for filetype 'gitcommit'
        cmp.setup.filetype("gitcommit", {
            sources = {{
                name = "git"
            }, {
                name = "buffer"
            }, {
                name = "path"
            }}
        })

        -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
        cmp.setup.cmdline({"/", "?"}, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {{
                name = "buffer"
            }}
        })

        -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({{
                name = "path"
            }}, {{
                name = "cmdline"
            }})
        })
    end
}}

return M
