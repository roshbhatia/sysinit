local M = {}

M.plugins = {{
    "hrsh7th/nvim-cmp",
    lazy = false,
    dependencies = { -- Core completion plugins
    "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline", "onsails/lspkind.nvim",
    -- Copilot integration
    "github/copilot.vim", "zbirenbaum/copilot.lua", "zbirenbaum/copilot-cmp", -- Avante integration for chat
    "yetone/avante.nvim", "nvim-lua/plenary.nvim", "CopilotC-Nvim/CopilotChat.nvim", "MunifTanjim/nui.nvim",
    -- Support plugins
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

        -- Improved function to check Copilot status
        local function is_copilot_online()
            local copilot_status = vim.fn.system("nvim --headless -c 'Copilot status' -c 'q'")
            return string.find(string.lower(copilot_status), "online") ~= nil
        end

        -- Initialize minimal LuaSnip setup (for compatibility with cmp)
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

        -- Completely disable the native Copilot inline suggestions
        vim.g.copilot_no_tab_map = true
        vim.g.copilot_assume_mapped = true
        vim.g.copilot_tab_fallback = ""
        vim.api.nvim_set_var("copilot_enabled", false)

        -- Check if Copilot is online and set up related features
        if is_copilot_online() then
            -- Setup Copilot.lua with suggestions disabled
            require("copilot").setup({
                suggestion = {
                    enabled = false,
                    auto_trigger = false,
                    debounce = 75,
                    keymap = {
                        accept = false,
                        accept_word = false,
                        accept_line = false,
                        next = false,
                        prev = false,
                        dismiss = false
                    }
                },
                panel = {
                    enabled = false
                },
                filetypes = {
                    ["*"] = true,
                    ["help"] = false,
                    ["gitcommit"] = false,
                    ["gitrebase"] = false,
                    ["hgcommit"] = false,
                    ["svn"] = false,
                    ["cvs"] = false
                },
                copilot_node_command = 'node'
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

            -- CopilotChat config
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

            -- Build Avante
            vim.cmd("AvanteBuild")
        end

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

                -- Only add Copilot sources if it's online
                -- This prioritizes Copilot suggestions like in VS Code
                if is_copilot_online() then
                    table.insert(base_sources, 1, {
                        name = 'copilot',
                        group_index = 1,
                        priority = 100,
                        max_item_count = 10
                    })
                end

                -- Keep snippets with lower priority since you don't use them much
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

                    -- Put Copilot suggestions at the top when available
                    if is_copilot_online() then
                        table.insert(comparators, 1, require("copilot_cmp.comparators").prioritize)
                    end

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

        -- Print setup completion message
        vim.defer_fn(function()
            if is_copilot_online() then
                vim.notify("Completion setup with Copilot integration", vim.log.levels.INFO)
            else
                vim.notify("Completion setup with LSP only (Copilot not connected)", vim.log.levels.WARN)
            end
        end, 1000)
    end
}}

return M
