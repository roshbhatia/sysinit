local M = {}

M.plugins = {
	{
		"rachartier/tiny-glimmer.nvim",
		event = "VeryLazy",
		priority = 10,
		config = function()
			require("tiny-glimmer").setup({
				enabled = true,
				overwrite = {
					search = {
						enabled = true,
					},
					undo = {
						enabled = true,
						undo_mapping = "u",
					},
					redo = {
						enabled = true,
						redo_mapping = "U",
					},
				},
				transparency_color = "#949cbb",
			})
		end,
	},
}

return M

