local M = {}
local copilot_enabled = not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot"))

local deps = {
	"folke/lazydev.nvim",
	"giuxtaposition/blink-cmp-copilot",
	"Kaiser-Yang/blink-cmp-git",
	"L3MON4D3/LuaSnip",
	"onsails/lspkind.nvim",
	"pwntester/octo.nvim",
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
					transform_items = function(ctx, items)
						for _, item in ipairs(items) do
							item.kind_icon = " Buffer "
							item.kind_name = "Buffer"
						end
						return items
					end,
				},
				git = {
					module = "blink-cmp-git",
					name = "Git",
					enabled = function()
						return vim.tbl_contains({ "octo", "gitcommit", "markdown" }, vim.bo.filetype)
					end,
					transform_items = function(ctx, items)
						for _, item in ipairs(items) do
							item.kind_icon = " Git "
							item.kind_name = "Git"
						end
						return items
					end,
					score_offset = 0,
				},
				go_pkgs = {
					enabled = function()
						return vim.tbl_contains({ "go" }, vim.bo.filetype)
					end,
					module = "blink.compat.source",
					name = "Go Packages",
					cmp_name = "go_pkgs",
					transform_items = function(ctx, items)
						for _, item in ipairs(items) do
							item.kind_icon = " Go Packages "
							item.kind_name = "Go Packages"
						end
						return items
					end,
					async = true,
					score_offset = 0,
				},
				lazydev = {
					enabled = function()
						return vim.tbl_contains({ "lua" }, vim.bo.filetype)
					end,
					module = "lazydev.integrations.blink",
					name = "LazyDev",
					transform_items = function(ctx, items)
						for _, item in ipairs(items) do
							item.kind_icon = "⏾ LazyDev "
							item.kind_name = "LazyDev"
						end
						return items
					end,
					score_offset = 0,
				},
				lsp = {
					score_offset = 0,
					transform_items = function(ctx, items)
						for _, item in ipairs(items) do
							item.kind_icon = "󰘧 LSP "
							item.kind_name = "LSP"
						end
						return items
					end,
				},
				path = {
					score_offset = 1,
					transform_items = function(ctx, items)
						for _, item in ipairs(items) do
							item.kind_icon = " Path "
							item.kind_name = "Path"
						end
						return items
					end,
					opts = {
						show_hidden_files_by_default = true,
					},
				},
				snippets = {
					score_offset = 2,
					transform_items = function(ctx, items)
						for _, item in ipairs(items) do
							item.kind_icon = "󰩫 Snippets "
							item.kind_name = "Snippets"
						end
						return items
					end,
				},
				treesitter = {
					module = "blink.compat.source",
					cmp_name = "treesitter",
					name = "Treesitter",
					score_offset = 1,
					transform_items = function(ctx, items)
						for _, item in ipairs(items) do
							item.kind_icon = "󱁇 Treesitter "
							item.kind_name = "Treesitter"
						end
						return items
					end,
					opts = {
						keyword_length = 2,
					},
				},
			}

			local sources = {
				"buffer",
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
					transform_items = function(ctx, items)
						for _, item in ipairs(items) do
							item.kind_icon = ""
							item.kind_name = "Copilot"
						end
						return items
					end,
				}
				table.insert(sources, "copilot")
			end

			return {
				completion = {
					accept = {
						create_undo_point = true,
					},
					documentation = {
						auto_show = true,
						auto_show_delay_ms = 0,
					},
					ghost_text = {
						enabled = true,
					},
					list = {
						selection = {
							preselect = true,
							auto_insert = true,
						},
					},
				},
				cmdline = {
					enabled = false,
				},
				fuzzy = {
					implementation = "prefer_rust",
				},
				keymap = {
					preset = "super-tab",
					["<C-\\>"] = { "show" },
					["<CR>"] = { "accept", "fallback" },
					["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
					["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				},
				signature = {
					enabled = true,
				},
				sources = {
					default = sources,
					providers = providers,
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
