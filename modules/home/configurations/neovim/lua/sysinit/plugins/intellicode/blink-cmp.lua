local M = {}
local copilot_enabled = not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot"))

local deps = {
	"giuxtaposition/blink-cmp-copilot",
	"hrsh7th/cmp-cmdline",
	"Kaiser-Yang/blink-cmp-dictionary",
	"Kaiser-Yang/blink-cmp-git",
	"L3MON4D3/LuaSnip",
	"rafamadriz/friendly-snippets",
	"ray-x/cmp-treesitter",
	"saghen/blink.compat",
	"Snikimonkd/cmp-go-pkgs",
}

if copilot_enabled then
	table.insert(deps, "giuxtaposition/blink-cmp-copilot")
end

M.plugins = {
	{
		"saghen/blink.cmp",
		event = {
			"BufReadPost",
		},
		dependencies = deps,
		version = "v1.*",
		opts = function()
			local providers = {
				dictionary = {
					module = "blink-cmp-dictionary",
					name = "Dict",
					min_keyword_length = 3,
					opts = {},
				},
				git = {
					module = "blink-cmp-git",
					name = "Git",
					opts = {},
				},
				go_pkgs = {
					module = "blink.compat.source",
					name = "go_pkgs",
					score_offset = 50,
					opts = {
						matching = {
							disallow_symbol_nonprefix_matching = false,
						},
					},
				},
				lazydev = {
					module = "lazydev.integrations.blink",
					name = "LazyDev",
					score_offset = 100,
				},
				treesitter = {
					module = "blink.compat.source",
					name = "treesitter",
					score_offset = 75,
					opts = {
						keyword_length = 2,
					},
				},
			}

			local default_sources = {
				"buffer",
				"cmdline",
				"dictionary",
				"git",
				"go-pkgs",
				"lazydev",
				"lsp",
				"luasnip",
				"path",
				"treesitter",
			}

			if copilot_enabled then
				providers.copilot = {
					name = "copilot",
					module = "blink-cmp-copilot",
					score_offset = 100,
					async = true,
				}
				table.insert(default_sources, "copilot")
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
		opts_extend = {
			"sources.default",
		},
	},
}

return M
