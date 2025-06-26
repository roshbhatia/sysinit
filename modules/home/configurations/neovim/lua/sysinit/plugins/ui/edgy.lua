local M = {}

M.plugins = {
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		config = function()
			vim.opt.splitkeep = "topline"

			require("edgy").setup({
				animate = {
					enabled = true,
				},
				options = {
					left = {
						size = 40,
					},
					right = {
						size = 60,
					},
					bottom = {
						size = 0,
					},
				},
				left = {
					{
						title = " File Explorer",
						ft = "neo-tree",
						filter = function(buf)
							return vim.b[buf].neo_tree_source == "filesystem"
						end,
					},
				},
				right = {
					{
						title = " Copilot",
						ft = "Avante",
					},
					{
						ft = "AvanteSelectedFiles",
						size = 25,
					},
					{
						ft = "AvanteTodos",
						size = 25,
					},
					{
						ft = "AvanteInput",
						size = 45,
					},
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

