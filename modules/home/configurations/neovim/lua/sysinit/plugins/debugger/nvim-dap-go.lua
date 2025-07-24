local M = {}

M.plugins = {
	{
		"leoluz/nvim-dap-go",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		ft = { "go" },
		config = function()
			require("dap-go").setup()
		end,
	},
}

return M

