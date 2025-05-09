local M = {}

M.plugins = {
	{
		"AckslD/muren.nvim",
		config = true,
		keys = function()
			return {
				{
					"<leader>fg",
					function()
						require("muren").toggle()
					end,
					desc = "Find: Global search",
				},
			}
		end,
	},
}

return M

