local M = {}

M.plugins = {
	{
		"shellRaining/hlchunk.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("hlchunk").setup({
				line_num = {
					enablechunk = true,
				},
			})
		end,
	},
}

return M

