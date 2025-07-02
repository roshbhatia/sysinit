local M = {}

M.plugins = {
	{
		"pta2002/intellitab.nvim",
		event = "BufReadPost",
		keys = function()
			return {
				{
					"<Tab>",
					function()
						require("intellitab").indent()
					end,
					mode = "i",
					noremap = true,
					silent = true,
					desc = "Smart tab",
				},
			}
		end,
	},
}

return M
