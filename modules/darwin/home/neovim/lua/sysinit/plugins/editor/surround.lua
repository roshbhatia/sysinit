local M = {}

M.plugins = {
	{
		"echasnovski/mini.surround",
		event = "InsertEnter",
		version = "*",
		config = function()
			require("mini.surround").setup()
		end,
	},
}

return M
