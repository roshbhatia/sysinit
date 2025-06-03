local M = {}

M.plugins = {
	{
		"rachartier/tiny-glimmer.nvim",
		event = "BufReadPost",
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
			})
		end,
	},
}

return M

