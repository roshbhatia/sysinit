local M = {}

M.plugins = {
	{
		"saghen/blink.compat",
		version = "v2.*",
		lazy = true,
		opts = {},
	},
	{
		"saghen/blink.cmp",
		event = { "BufReadPost" },
		dependencies = {
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lua",
			"L3MON4D3/LuaSnip",
			"petertriho/cmp-git",
			"rafamadriz/friendly-snippets",
			"ray-x/cmp-treesitter",
			"saghen/blink.compat",
			"Snikimonkd/cmp-go-pkgs",
			"zbirenbaum/copilot-cmp",
		},
		version = "v1.*",
		opts = {
			completion = {
				documentation = {
					auto_show = true,
				},
				accept = {
					create_undo_point = true,
				},
			},
			keymap = {
				preset = "super-tab",
			},
			providers = {
				buffer = {
					name = "buffer",
					enabled = true,
					score_offset = 70,
					opts = {
						keyword_length = 3,
						max_item_count = 5,
					},
				},
				copilot = {
					name = "copilot",
					module = "blink.compat.source",
					score_offset = 100,
					opts = {
						keyword_length = 2,
						max_item_count = 5,
					},
				},
				git = {
					name = "git",
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
				nvim_lua = {
					name = "nvim_lua",
					module = "blink.compat.source",
					score_offset = 50,
					opts = {},
				},
				path = {
					name = "path",
					enabled = true,
					score_offset = 60,
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
			},
			signature = {
				enabled = true,
			},
			sources = {
				default = {
					"buffer",
					"cmdline",
					"copilot",
					"git",
					"go-pkgs",
					"lazydev",
					"lsp",
					"nvim_lua",
					"path",
					"snippets",
					"treesitter",
				},
			},
		},
		opts_extend = { "sources.default" },
	},
}

return M
