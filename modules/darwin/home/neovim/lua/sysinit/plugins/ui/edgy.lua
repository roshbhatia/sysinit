local M = {}

M.plugins = {
	{
		c("folke/edgy.nvim"),
		event = "VeryLazy",
		config = function()
			vim.opt.splitkeep = "screen"

			require("edgy").setup({
				options = {
					left = {
						size = 55,
					},
					right = {
						size = 55,
					},
				},
				left = {
					{
						title = " Explorer",
						ft = "neo-tree",
						filter = function(buf)
							return vim.b[buf].neo_tree_source == "filesystem"
						end,
						size = { height = 0.5 },
					},
					"neo-tree",
				},
				right = {
					{
						ft = "avante",
						size = { height = 0.66 },
					},
					{
						ft = "avante-selected-files",
						size = { height = 0.14 },
					},
					{
						ft = "avante-input",
						size = { height = 0.2 }, -- remaining space
					},
				},
			})
		end,
	},
}

return M

