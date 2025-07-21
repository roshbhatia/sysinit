local M = {}

M.plugins = {
	{
		"Bekaboo/dropbar.nvim",
		lazy = false,
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		config = function()
			require("dropbar").setup({
				icons = {
					ui = {
						bar = {
							separator = "  ",
							extends = "…",
						},
					},
				},
				menu = {
					preview = false,
					scrollbar = {
						enable = false,
					},
				},
				bar = {
					pick = {
						pivots = "fjdkslaghrueiwoncmv",
					},
				},
				sources = function(buf, _)
					local sources = require("dropbar.sources")
					if vim.bo[buf].ft == "markdown" then
						return {
							sources.path,
							sources.markdown,
						}
					end
					if vim.bo[buf].buftype == "terminal" then
						return {
							sources.terminal,
						}
					end
					return {
						sources.path,
						utils.source.fallback({
							sources.treesitter,
						}),
					}
				end,
			})
		end,
		keys = function()
			local dropbar_api = require("dropbar.api")
			return {
				{
					"<leader>fw",
					dropbar_api.pick,
					mode = "n",
					desc = "Symbols in winbar",
				},
			}
		end,
	},
}

return M

