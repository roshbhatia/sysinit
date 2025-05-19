local M = {}

M.plugins = {
	{
		"rcarriga/nvim-dap-ui",
		commit = "73a26abf4941aa27da59820fd6b028ebcdbcf932",
		lazy = true,
		dependencies = {
			"nvim-neotest/nvim-nio",
			"mfussenegger/nvim-dap",
		},
		config = true,
		keys = function()
			return {
				{
					"<leader>du",
					function()
						require("dapui").toggle({})
					end,
					desc = "Debugger: UI",
				},
			}
		end,
	},
}

return M

