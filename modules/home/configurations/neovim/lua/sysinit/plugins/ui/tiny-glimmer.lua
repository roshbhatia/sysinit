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
					},
					redo = {
						enabled = true,
						redo_mapping = "U",
					},
				},
				transparency_color = "auto",
			})
		end,
	},
}

return M

