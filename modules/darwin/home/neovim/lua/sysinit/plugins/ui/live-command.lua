local M = {}

M.plugins = {
	{
		"smjonas/live-command.nvim",
		config = function()
			require("live-command").setup()
		end,
	},
}

return M
