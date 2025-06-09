local M = {}
local copilot_enabled = not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot"))

local deps = {
	"folke/lazydev.nvim",
	"giuxtaposition/blink-cmp-copilot",
	"hrsh7th/cmp-cmdline",
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
		lazy = true,
		dependencies = deps,
		version = "v1.*",
		opts = function()
			local providers = {
				buffer = {
					score_offset = 3,
				},
				git = {
					module = "blink-cmp-git",
					name = "Git",
					enabled = function()
						return vim.tbl_contains({ "octo", "gitcommit", "markdown" }, vim.bo.filetype)
					end,
					opts = {},
					score_offset = 0,
				},
				go_pkgs = {
					enabled = function()
						return not vim.tbl_contains({ "go" }, vim.bo.filetype)
					end,
					module = "blink.compat.source",
					name = "go_pkgs",
					async = true,
					score_offset = 0,
				},
				lazydev = {
					enabled = function()
						return not vim.tbl_contains({ "lua" }, vim.bo.filetype)
					end,
					module = "lazydev.integrations.blink",
					name = "LazyDev",
					score_offset = 0,
				},
				lsp = {
					score_offset = 0,
				},
				path = {
					score_offset = 1,
				},
				snippets = {
					score_offset = 2,
				},
				treesitter = {
					module = "blink.compat.source",
					name = "treesitter",
					score_offset = 1,
					opts = {
						keyword_length = 2,
					},
				},
			}

			local default_sources = {
				"buffer",
				"cmdline",
				"git",
				"go_pkgs",
				"lazydev",
				"lsp",
				"path",
				"snippets",
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
				snippets = {
					preset = "luasnip",
				},
			}
		end,
		opts_extend = {
			"sources.default",
		},
	},
}

return M
