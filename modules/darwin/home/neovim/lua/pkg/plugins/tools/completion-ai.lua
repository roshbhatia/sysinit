local M = {}

M.plugins = {{
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            suggestion = {
                enabled = false,
                auto_trigger = false
            },
            copilot_model = "gpt-4o-copilot"

        })
    end
}, {
    "hrsh7th/nvim-cmp",
    lazy = true,
    dependencies = { -- Core completion plugins
    "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline", "onsails/lspkind.nvim",
    -- Copilot integration
    "zbirenbaum/copilot-cmp", -- Avante integration for chat
    "yetone/avante.nvim", "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", -- Support plugins
    "nvim-treesitter/nvim-treesitter", "stevearc/dressing.nvim", "HakonHarnes/img-clip.nvim",
    "MeanderingProgrammer/render-markdown.nvim", "NMAC427/guess-indent.nvim", -- Added guess-indent instead of intellitab
    "windwp/nvim-autopairs", -- Snippets (kept for compatibility)
    "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip", "rafamadriz/friendly-snippets"},
    config = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')
        local lspkind = require('lspkind')
        local autopairs = require('nvim-autopairs')

        -- Utility functions for context awareness
        local has_words_before = function()
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
        end

        local get_line_context = function()
            local line = vim.api.nvim_get_current_line()
            local cursor = vim.api.nvim_win_get_cursor(0)
            local col = cursor[2]

            return {
                line = line,
                before_cursor = line:sub(1, col),
                after_cursor = line:sub(col + 1),
                col = col,
                is_empty_line = line:match("^%s*$") ~= nil,
                at_indent_position = line:sub(1, col):match("^%s*$") ~= nil,
                has_text_after_cursor = line:sub(col + 1):match("%S") ~= nil
            }
        end

        require("luasnip.loaders.from_vscode").lazy_load()

        -- Setup guess-indent for automatic indentation style detection
        require('guess-indent').setup({
            auto_cmd = true, -- Automatically detect indentation when a file is opened
            override_editorconfig = false, -- Don't override editorconfig settings
            filetype_exclude = {"netrw", "help", "terminal", "prompt", "NvimTree", "TelescopePrompt", "mason",
                                "lspinfo", "packer", "checkhealth", "help", "man", "git", "fugitive"},
            buftype_exclude = {"help", "nofile", "terminal", "prompt"},
            -- Options to apply when tabs are detected
            on_tab_options = {
                ["expandtab"] = false,
                ["tabstop"] = 4,
                ["shiftwidth"] = 4,
                ["softtabstop"] = 0
            },
            -- Options to apply when spaces are detected
            on_space_options = {
                ["expandtab"] = true,
                ["tabstop"] = "detected", -- Use the detected indentation size
                ["shiftwidth"] = "detected",
                ["softtabstop"] = "detected"
            }
        })

        -- Configure Copilot-cmp
        require("copilot_cmp").setup({
            method = "getCompletionsCycling",
            formatters = {
                label = require("copilot_cmp.format").format_label_text,
                insert_text = require("copilot_cmp.format").format_insert_text,
                preview = require("copilot_cmp.format").deindent
            }
        })

        -- Setup Avante (only for chat, not suggestions)
        require("avante").setup({
            provider = "copilot",
            behaviour = {
                auto_suggestions = false, -- Disabled as per request
                auto_set_highlight_group = true,
                auto_set_keymaps = true,
                minimize_diff = true,
                enable_token_counting = true,
                enable_cursor_planning_mode = true
            },
            windows = {
                position = "right",
                wrap = true,
                width = 30
            },
            mappings = {
                suggestion = {
                    accept = "<M-l>",
                    next = "<M-]>",
                    prev = "<M-[>",
                    dismiss = "<C-]>"
                }
            }
        })

        -- Setup image clip for Avante
        require("img-clip").setup({
            default = {
                embed_image_as_base64 = false,
                prompt_for_file_name = false,
                drag_and_drop = {
                    insert_mode = true
                },
                use_absolute_path = true
            }
        })

        -- Setup markdown rendering for Avante
        require("render-markdown").setup({
            file_types = {"markdown", "Avante"}
        })

        -- Configure nvim-cmp with a slicker appearance
        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end
            },
            window = {
                -- Enhanced window styling for a more modern look
                completion = cmp.config.window.bordered({
                    border = "single",
                    winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None",
                    scrollbar = true,
                    col_offset = -3,
                    side_padding = 1
                }),
                documentation = cmp.config.window.bordered({
                    border = "rounded",
                    winhighlight = "Normal:CmpDoc,FloatBorder:CmpDocBorder",
                    max_width = 80,
                    max_height = 20
                })
            },
            formatting = {
                -- Enhanced formatting for a VS Code-like experience
                format = lspkind.cmp_format({
                    mode = 'symbol_text',
                    maxwidth = 50,
                    ellipsis_char = '…', -- Unicode ellipsis for cleaner look
                    symbol_map = {
                        Copilot = "󰚩", -- Enhanced Copilot icon
                        Text = "󰉿",
                        Method = "󰆧",
                        Function = "󰊕",
                        Constructor = "",
                        Field = "󰜢",
                        Variable = "󰀫",
                        Class = "󰠱",
                        Interface = "",
                        Module = "",
                        Property = "󰜢",
                        Unit = "󰑭",
                        Value = "󰎠",
                        Enum = "",
                        Keyword = "󰌋",
                        Snippet = "",
                        Color = "󰏘",
                        File = "󰈙",
                        Reference = "󰈇",
                        Folder = "󰉋",
                        EnumMember = "",
                        Constant = "󰏿",
                        Struct = "󰙅",
                        Event = "",
                        Operator = "󰆕"
                    },
                    menu = {
                        buffer = "  Buffer",
                        nvim_lsp = "  LSP",
                        luasnip = "  Snippet",
                        path = "  Path",
                        copilot = "  Copilot",
                        avante = "  Avante"
                    },
                    before = function(entry, vim_item)
                        -- Improved item display formatting
                        vim_item.abbr = string.sub(vim_item.abbr, 1, 50)

                        -- Special styling for Copilot items to make them stand out
                        local source = entry.source.name
                        if source == "copilot" then
                            vim_item.kind_hl_group = "CmpItemKindCopilot"
                            -- Priority hint for Copilot suggestions
                            vim_item.dup = 0
                        end

                        return vim_item
                    end
                })
            },
            sources = function()
                -- Base sources that are always available
                local base_sources = {{
                    name = 'nvim_lsp',
                    group_index = 1,
                    priority = 90
                }, {
                    name = 'path',
                    group_index = 2,
                    priority = 60
                }, {
                    name = 'buffer',
                    group_index = 3,
                    keyword_length = 3,
                    priority = 40
                }}

                table.insert(base_sources, 1, {
                    name = 'copilot',
                    group_index = 1,
                    priority = 100,
                    max_item_count = 10
                })

                table.insert(base_sources, {
                    name = 'luasnip',
                    group_index = 2,
                    priority = 50
                })

                return base_sources
            end,
            mapping = cmp.mapping.preset.insert({
                -- VS Code-like keybindings
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-j>'] = cmp.mapping.select_next_item(),
                ['<C-k>'] = cmp.mapping.select_prev_item(),

                -- Enter key behavior
                ['<CR>'] = cmp.mapping({
                    i = function(fallback)
                        if cmp.visible() then
                            cmp.confirm({
                                select = true,
                                behavior = cmp.ConfirmBehavior.Replace
                            })
                        else
                            fallback()
                        end
                    end,
                    s = cmp.mapping.confirm({
                        select = true,
                        behavior = cmp.ConfirmBehavior.Replace
                    }),
                    c = function(fallback)
                        if cmp.visible() then
                            cmp.confirm({
                                select = true,
                                behavior = cmp.ConfirmBehavior.Replace
                            })
                        else
                            fallback()
                        end
                    end
                }),

                -- Enhanced Tab behavior similar to VS Code
                ['<Tab>'] = cmp.mapping(function(fallback)
                    -- Handle visible completion menu first
                    if cmp.visible() then
                        cmp.select_next_item()
                        return
                    end

                    -- If we have text before cursor, try completing
                    if has_words_before() then
                        cmp.complete()
                        if cmp.visible() then
                            cmp.select_next_item()
                            return
                        end
                    end

                    -- Default to standard tab behavior
                    fallback()
                end, {'i', 's'}),

                ['<S-Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    else
                        fallback()
                    end
                end, {'i', 's'})
            }),
            -- VS Code-like behavior settings
            preselect = cmp.PreselectMode.Item,
            experimental = {
                ghost_text = true -- Keep lookahead suggestions
            },
            matching = {
                disallow_fuzzy_matching = false,
                disallow_partial_matching = false,
                disallow_prefix_unmatching = false
            },
            sorting = {
                priority_weight = 2,
                comparators = function()
                    local comparators = {cmp.config.compare.exact, cmp.config.compare.score,
                                         cmp.config.compare.recently_used, cmp.config.compare.locality,
                                         cmp.config.compare.kind, cmp.config.compare.sort_text,
                                         cmp.config.compare.length, cmp.config.compare.order}

                    table.insert(comparators, 1, require("copilot_cmp.comparators").prioritize)
                    return comparators
                end
            },
            -- Improve performance with debouncing
            performance = {
                debounce = 60,
                throttle = 30,
                fetching_timeout = 200
            }
        })

        -- Special configuration for gitcommit files
        cmp.setup.filetype('gitcommit', {
            sources = cmp.config.sources({{
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

        -- Setup autopairs to work with CMP
        cmp.event:on('confirm_done', require('nvim-autopairs.completion.cmp').on_confirm_done())

        -- Set up visual mode indentation key mappings to work like VSCode
        -- This allows selecting a block and pressing Tab to indent it all
        vim.keymap.set('v', '<Tab>', '>gv', {
            silent = true,
            noremap = true
        })

        vim.keymap.set('v', '<S-Tab>', '<gv', {
            silent = true,
            noremap = true
        })

        -- Set up enhanced highlight groups for a more attractive completion menu
        vim.api.nvim_set_hl(0, "CmpPmenu", {
            bg = "#1E1E1E",
            fg = "#D4D4D4"
        })
        vim.api.nvim_set_hl(0, "CmpPmenuBorder", {
            fg = "#3E3E3E"
        })
        vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", {
            fg = "#569CD6",
            bold = true
        })
        vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", {
            fg = "#569CD6",
            bold = true
        })
        vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {
            fg = "#6CC644",
            bold = true
        })
        vim.api.nvim_set_hl(0, "CmpItemKindVariable", {
            fg = "#9CDCFE"
        })
        vim.api.nvim_set_hl(0, "CmpItemKindFunction", {
            fg = "#C586C0"
        })
        vim.api.nvim_set_hl(0, "CmpItemKindMethod", {
            fg = "#DCDCAA"
        })
        vim.api.nvim_set_hl(0, "CmpDoc", {
            bg = "#252525"
        })
        vim.api.nvim_set_hl(0, "CmpDocBorder", {
            fg = "#454545"
        })

        -- Enable auto-pairing (like in VS Code)
        require("nvim-autopairs").setup({
            check_ts = true,
            ts_config = {
                lua = {'string'},
                javascript = {'template_string'}
            },
            fast_wrap = {
                map = '<M-e>', -- Alt+e to wrap with pairs
                chars = {'{', '[', '(', '"', "'"},
                pattern = [=[[%'%"%>%]%)%}%,]]=],
                end_key = '$',
                keys = 'qwertyuiopzxcvbnmasdfghjkl',
                check_comma = true,
                highlight = 'Search',
                highlight_grey = 'Comment'
            }
        })
    end
}}

return M
