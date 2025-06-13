local M = {}

M.plugins = {
	{
		"leoluz/nvim-dap-go",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		config = function()
			require("dap-go").setup()
		end,
	},
}

return M

