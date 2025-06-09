local M = {}

M.plugins = {
	{
		"saghen/blink.cmp",
		event = {
			"BufReadPost",
		},
		dependencies = function()
			local deps = {
				"hrsh7th/cmp-cmdline",
				"hrsh7th/cmp-nvim-lua",
				"L3MON4D3/LuaSnip",
				"petertriho/cmp-git",
				"rafamadriz/friendly-snippets",
				"ray-x/cmp-treesitter",
				"saghen/blink.compat",
				"saghen/blink.compat",
				"Snikimonkd/cmp-go-pkgs",
			}

			if not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot")) then
				table.insert(deps, "zbirenbaum/copilot-cmp")
			end

			return deps
		end,
		version = "v1.*",
		opts = function()
			local copilot_enabled = not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot"))

			local providers = {
				buffer = {
					name = "buffer",
					enabled = true,
					score_offset = 70,
					opts = {
						keyword_length = 3,
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
			}

			local default_sources = {
				"buffer",
				"cmdline",
				"git",
				"go-pkgs",
				"lazydev",
				"lsp",
				"nvim_lua",
				"path",
				"snippets",
				"treesitter",
			}

			if copilot_enabled then
				providers.copilot = {
					name = "copilot",
					module = "blink.compat.source",
					score_offset = 100,
					opts = {
						keyword_length = 2,
						max_item_count = 5,
					},
				}
				table.insert(default_sources, 3, "copilot")
			end

			return {
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
				providers = providers,
				signature = {
					enabled = true,
				},
				sources = {
					default = default_sources,
				},
			}
		end,
		opts_extend = { "sources.default" },
	},
}

return M
