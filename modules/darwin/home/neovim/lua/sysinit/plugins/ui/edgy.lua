local M = {}

M.plugins = {
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		config = function()
			vim.opt.splitkeep = "topline"

			require("edgy").setup({
				options = {
					left = {
						size = 40,
					},
					bottom = {
						size = 0,
					},
				},
				left = {
					{
						title = " Explorer",
						ft = "neo-tree",
						filter = function(buf)
							return vim.b[buf].neo_tree_source == "filesystem"
						end,
					},
					"neo-tree",
				},
				right = {
					{
						title = "󰪧 Outline",
						ft = "aerial",
						size = {
							width = 40,
						},
					},
					"aerial",
				},
				icons = {
					closed = "",
					open = "",
				},
			})
		end,
	},
}

return M
