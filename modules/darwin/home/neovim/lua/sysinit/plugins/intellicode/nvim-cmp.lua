local M = {}

M.plugins = {{
    "hrsh7th/nvim-cmp",
    lazy = true,
    dependencies = {"VonHeikemen/lsp-zero.nvim", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline",
                    "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-nvim-lua", "zbirenbaum/copilot-cmp", "petertriho/cmp-git",
                    "L3MON4D3/LuaSnip"},
    after = {"VonHeikemen/lsp-zero.nvim", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline",
             "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-nvim-lua", "zbirenbaum/copilot-cmp", "petertriho/cmp-git",
             "L3MON4D3/LuaSnip"},
    event = "InsertEnter",
    config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        local has_words_before = function()
            if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
                return false
            end
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
        end

        local kind_icons = {
            Text = "󰦨",
            Method = "m",
            Function = "󰡱",
            Constructor = "",
            Field = "",
            Variable = "󰫧",
            Class = "",
            Interface = "",
            Module = "",
            Property = "",
            Unit = "",
            Value = "",
            Enum = "",
            Keyword = "",
            Snippet = "",
            Color = "",
            File = "",
            Reference = "",
            Folder = "",
            EnumMember = "",
            Constant = "",
            Struct = "",
            Event = "",
            Operator = "",
            TypeParameter = "",
            Copilot = ""
        }

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered()
            },
            sorting = {
                priority_weight = 2,
                comparators = {require("copilot_cmp.comparators").prioritize,

                -- Below is the default comparitor list and order for nvim-cmp
                               cmp.config.compare.offset,
                -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
                               cmp.config.compare.exact, cmp.config.compare.score, cmp.config.compare.recently_used,
                               cmp.config.compare.locality, cmp.config.compare.kind, cmp.config.compare.sort_text,
                               cmp.config.compare.length, cmp.config.compare.order}
            },
            formatting = {
                fields = {"kind", "abbr", "menu"},
                format = function(entry, vim_item)
                    vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
                    vim_item.menu = ({
                        copilot = "[Copilot]",
                        nvim_lsp = "[LSP]",
                        luasnip = "[Snippet]",
                        buffer = "[Buffer]",
                        path = "[Path]"
                    })[entry.source.name]
                    return vim_item
                end
            },
            sources = cmp.config.sources({{
                name = "copilot",
                group_index = 2
            }, {
                name = "nvim_lsp",
                group_index = 2
            }, {
                name = "luasnip",
                group_index = 2
            }, {
                name = "path",
                group_index = 2
            }, {
                name = "buffer",
                group_index = 2
            }}),
            mapping = cmp.mapping.preset.insert({
                ["<CR>"] = cmp.mapping.confirm({
                    behavior = cmp.ConfirmBehavior.Replace,
                    select = false
                }),
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() and has_words_before() then
                        cmp.select_next_item({
                            behavior = cmp.SelectBehavior.Select
                        })
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
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
            })
        })

        cmp.setup.filetype("gitcommit", {
            sources = cmp.config.sources({{
                name = "git"
            }}, {{
                name = "buffer"
            }})
        })

        cmp.setup.cmdline({"/", "?"}, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {{
                name = "buffer"
            }}
        })

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

