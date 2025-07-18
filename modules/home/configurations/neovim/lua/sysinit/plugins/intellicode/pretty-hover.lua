local M = {}

M.plugins = {
	{
		"Fildo7525/pretty_hover",
		opts = {},
		keys = function()
			return {
				{
					"<leader>ch",
					function()
						require("pretty_hover").hover()
					end,
					desc = "Hover documentation",
				},
			}
		end,
	},
}

return M
