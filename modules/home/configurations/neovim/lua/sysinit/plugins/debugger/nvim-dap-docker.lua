local M = {}

M.plugins = {
	{
		"docker/nvim-dap-docker",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		config = function()
			require("dap-docker").setup()
		end,
	},
}

return M
