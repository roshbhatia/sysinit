local M = {}

M.plugins = {{
    "hrsh7th/cmp-buffer",
    lazy = true
}, {
    "hrsh7th/cmp-path",
    lazy = true
}, {
    "hrsh7th/cmp-cmdline",
    lazy = true
}, {
    "hrsh7th/cmp-nvim-lsp",
    lazy = true
}, {
    "hrsh7th/cmp-nvim-lua",
    lazy = true
}, {
    "zbirenbaum/copilot-cmp",
    lazy = true,
    dependencies = {"zbirenbaum/copilot.lua"}
}, {
    "petertriho/cmp-git",
    lazy = true
}, {
    "hrsh7th/nvim-cmp",
    lazy = true,
    dependencies = {"VonHeikemen/lsp-zero.nvim", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline",
                    "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-nvim-lua", "zbirenbaum/copilot-cmp", "petertriho/cmp-git"},
    event = "InsertEnter",
    config = function()
        local cmp = require("cmp")

        cmp.setup({
            formatting = {
                format = function(entry, vim_item)
                    if vim_item.kind == "Copilot" then
                        vim_item.kind = ""
                        vim_item.kind_hl_group = "CmpItemKindCopilot"
                    end
                    return vim_item
                end
            },
            sources = function()
                local base_sources = {{
                    name = "copilot",
                    group_index = 2
                }, {
                    name = "nvim_lsp",
                    group_index = 1
                }, {
                    name = "path",
                    group_index = 3
                }, {
                    name = "buffer",
                    group_index = 3
                }}
                return base_sources
            end,
            preselect = "item",
            matching = {
                disallow_fuzzy_matching = false,
                disallow_partial_matching = false,
                disallow_prefix_unmatching = false
            },
            sorting = {
                priority_weight = 2,
                comparators = function()
                    return {require("copilot_cmp.comparators").prioritize, require("cmp.config.compare").exact,
                            require("cmp.config.compare").score, require("cmp.config.compare").recently_used,
                            require("cmp.config.compare").locality, require("cmp.config.compare").kind,
                            require("cmp.config.compare").sort_text, require("cmp.config.compare").length,
                            require("cmp.config.compare").order}
                end
            },
            performance = {
                debounce = 60,
                throttle = 30,
                fetching_timeout = 200
            }
        })

        -- Special configuration for gitcommit files
        cmp.setup.filetype('gitcommit', {
            sources = cmp.config.sources({{
                name = 'git'
            }}, {{
                name = 'buffer'
            }})
        })

        -- Special configuration for search
        cmp.setup.cmdline({'/', '?'}, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {{
                name = 'buffer'
            }}
        })

        -- Special configuration for command mode
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

