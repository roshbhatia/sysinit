local M = {}

M.plugins = {
	{
		"pta2002/intellitab.nvim",
		commit = "955af8d74b07109d36729c623cb1bb232e25e16e",
		event = "InsertEnter",
		keys = function()
			return {
				{
					"<Tab>",
					function()
						require("intellitab").indent()
					end,
					mode = "v",
					noremap = true,
					silent = true,
				},
				{
					"<S-Tab>",
					"<gv",
					mode = "v",
					noremap = true,
					silent = true,
				},
			}
		end,
	},
}

return M

