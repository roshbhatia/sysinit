local M = {}

M.plugins = {
	{
		"smjonas/live-command.nvim",
		tag = "2.*",
		config = function()
			require("live-command").setup()
		end,
	},
}

return M
