local M = {}

M.plugins = {
	{
		"hrsh7th/nvim-cmp",
		event = { "BufReadPost" },
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"ray-x/cmp-treesitter",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"onsails/lspkind.nvim",
			"petertriho/cmp-git",
			"saadparwaiz1/cmp_luasnip",
			"pta2002/intellitab.nvim",
			"Snikimonkd/cmp-go-pkgs",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			-- Helper functions
			local has_words_before = function()
				unpack = unpack or table.unpack
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete({}),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({
						select = false,
					}),
					["<Tab>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						elseif has_words_before() then
							cmp.complete()
						else
							require("intellitab").indent()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				formatting = {
					format = lspkind.cmp_format({
						mode = "symbol_text",
						maxwidth = 50,
						ellipsis_char = "...",
						menu = {
							buffer = "",
							nvim_lsp = "󰘧",
							luasnip = "󰑷",
							nvim_lua = "",
							path = "",
							copilot = "",
						},
					}),
				},
				sources = {
					{
						name = "lazydev",
						group_index = 1,
					},
					{
						name = "nvim_lsp",
						group_index = 1,
					},
					{
						name = "copilot",
						group_index = 1,
					},
					{
						name = "luasnip",
						group_index = 1,
					},
					{
						name = "treesitter",
						group_index = 2,
						keyword_length = 2,
					},
					{
						name = "buffer",
						group_index = 2,
						keyword_length = 3,
						max_item_count = 5,
					},
					{
						name = "path",
						group_index = 2,
					},
					{
						name = "git",
						group_index = 2,
					},
					{
						name = "nvim_lua",
						group_index = 2,
					},
					{
						name = "go_pkgs",
						group_index = 2,
					},
				},
				sorting = {
					priority_weight = 2,
					comparators = {
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
				experimental = {
					ghost_text = true,
				},
			})
		end,
	},
}

return M
