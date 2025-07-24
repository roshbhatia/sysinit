local M = {}

M.plugins = {
	{
		"nvzone/menu",
		lazy = true,
		dependencies = {
			"nvzone/volt",
		},
		config = function()
			-- You can add global config here if needed
		end,
	},
}

return M
