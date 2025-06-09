local M = {}
M.plugins = {
	{
		"saghen/blink.compat",
		version = "v2.*", -- use v2.* for blink.cmp v1.*
		lazy = true,
		opts = {},
	},
	{
		"saghen/blink.cmp",
		event = { "BufReadPost" },
		dependencies = {
			"saghen/blink.compat",
			-- nvim-cmp sources that will be used through blink.compat
			"hrsh7th/cmp-cmdline",
			"ray-x/cmp-treesitter",
			"hrsh7th/cmp-nvim-lua",
			"petertriho/cmp-git",
			"Snikimonkd/cmp-go-pkgs",
			-- Snippet engine
			"L3MON4D3/LuaSnip",
			"rafamadriz/friendly-snippets",
			-- Formatting
			"onsails/lspkind.nvim",
		},
		version = "v1.*",
		opts = {
			keymap = {
				preset = "default",
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide" },
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = {
					function(cmp)
						if cmp.snippet_active() then
							return cmp.accept()
						else
							return cmp.select_and_accept()
						end
					end,
					"snippet_forward",
					"fallback",
				},
				["<S-Tab>"] = { "snippet_backward", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
			},

			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},

			sources = {
				default = {
					"lazydev",
					"lsp",
					"snippets",
					"treesitter",
					"buffer",
					"path",
					"git",
					"nvim_lua",
					"go_pkgs",
				},
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						score_offset = 100,
					},
					lsp = {
						name = "lsp",
						enabled = true,
						score_offset = 100,
					},
					snippets = {
						name = "snippets",
						enabled = true,
						score_offset = 85,
						opts = {
							preset = "luasnip",
							use_show_condition = false,
							show_autosnippets = true,
						},
					},
					treesitter = {
						name = "treesitter",
						module = "blink.compat.source",
						score_offset = 75,
						opts = {
							keyword_length = 2,
						},
					},
					buffer = {
						name = "buffer",
						enabled = true,
						score_offset = 70,
						opts = {
							keyword_length = 3,
							max_item_count = 5,
						},
					},
					path = {
						name = "path",
						enabled = true,
						score_offset = 60,
					},
					git = {
						name = "git",
						module = "blink.compat.source",
						score_offset = 50,
						opts = {},
					},
					nvim_lua = {
						name = "nvim_lua",
						module = "blink.compat.source",
						score_offset = 50,
						opts = {},
					},
					go_pkgs = {
						name = "go_pkgs",
						module = "blink.compat.source",
						score_offset = 50,
						opts = {},
					},
				},
			},

			signature = { enabled = true },

			completion = {
				accept = {
					auto_brackets = {
						enabled = true,
					},
				},
				menu = {
					enabled = true,
					min_width = 15,
					max_height = 10,
					border = "single",
					winblend = 0,
					scrolloff = 2,
					scrollbar = true,
					direction_priority = { "s", "n" },
					draw = {
						align_to_component = "label",
						padding = 1,
						gap = 1,
						columns = {
							{ "kind_icon" },
							{ "label", "label_description", gap = 1 },
							{ "source_name" },
						},
						components = {
							kind_icon = {
								ellipsis = false,
								text = function(ctx)
									local lspkind = require("lspkind")
									return lspkind.presets.default[ctx.kind] or ""
								end,
								highlight = function(ctx)
									return "CmpItemKind" .. (ctx.kind or "")
								end,
							},
							label = {
								width = { fill = true, max = 50 },
								text = function(ctx)
									return ctx.label .. (ctx.label_detail or "")
								end,
								highlight = function(ctx)
									local highlights = {
										{
											0,
											#ctx.label,
											group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
										},
									}
									if ctx.label_detail then
										table.insert(highlights, {
											#ctx.label,
											#ctx.label + #ctx.label_detail,
											group = "BlinkCmpLabelDetail",
										})
									end
									for _, idx in ipairs(ctx.label_matched_indices or {}) do
										table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
									end
									return highlights
								end,
							},
							label_description = {
								width = { max = 30 },
								text = function(ctx)
									return ctx.label_description
								end,
								highlight = "BlinkCmpLabelDescription",
							},
							source_name = {
								width = { max = 10 },
								text = function(ctx)
									local icons = {
										buffer = "",
										lsp = "󰘧",
										snippets = "󰑷",
										nvim_lua = "",
										path = "",
										git = "",
										treesitter = "",
										go_pkgs = "",
									}
									return icons[ctx.source_name] or ""
								end,
								highlight = "BlinkCmpSource",
							},
						},
					},
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					treesitter_highlighting = true,
					window = {
						min_width = 10,
						max_width = 60,
						max_height = 20,
						border = "single",
						winblend = 0,
						scrollbar = true,
						direction_priority = {
							menu_north = { "e", "w", "n", "s" },
							menu_south = { "e", "w", "s", "n" },
						},
					},
				},
				ghost_text = {
					enabled = true,
				},
			},
		},
		opts_extend = { "sources.default" },
	},
}
return M

