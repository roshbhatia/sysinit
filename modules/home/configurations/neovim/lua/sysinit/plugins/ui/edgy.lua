local M = {}

M.plugins = {
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		config = function()
			vim.opt.splitkeep = "topline"

			require("edgy").setup({
				animate = {
					enabled = false,
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
						title = " Explorer",
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
