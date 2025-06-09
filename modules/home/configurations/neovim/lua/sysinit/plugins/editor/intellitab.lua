local M = {}

M.plugins = {
	{
		"pta2002/intellitab.nvim",
		commit = "955af8d74b07109d36729c623cb1bb232e25e16e",
		event = "BufReadPost",
		opts = {},
		keys = function()
			return {
				{
					"<Tab>",
					function()
						require("intellitab").indent()
					end,
					desc = "Smart tab",
				},
			}
		end,
	},
}

return M
