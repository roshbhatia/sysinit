local M = {}

M.plugins = {
	{
		"rachartier/tiny-glimmer.nvim",
		event = "VeryLazy",
		priority = 10,
		config = function()
			require("tiny-glimmer").setup({
				search = {
					enabled = true,
				},
				undo = {
					enabled = true,
				},
				redo = {
					enabled = true,
					redo_mapping = "U",
				},
				transparency_color = "auto",
			})
		end,
	},
}

return M

