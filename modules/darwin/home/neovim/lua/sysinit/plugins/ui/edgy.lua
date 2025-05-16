local M = {}

M.plugins = {
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		config = function()
			vim.opt.splitkeep = "screen"

			require("edgy").setup({
				left = {
					{
						title = "Neo-Tree",
						ft = "neo-tree",
						filter = function(buf)
							return vim.b[buf].neo_tree_source == "filesystem"
						end,
						size = { height = 0.5 },
					},
					"neo-tree",
				},
				right = {
					"aerial",
					"Avante",
					"AvanteSelectedFiles",
					"AvanteInput",
				},
			})
		end,
	},
}

return M
