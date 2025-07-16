local M = {}

M.plugins = {
	{
		"rcarriga/nvim-dap-ui",
		lazy = true,
		dependencies = {
			"nvim-neotest/nvim-nio",
		},
		config = true,
		keys = function()
			return {
				{
					"<localleader>dd",
					function()
						require("dapui").toggle({})
					end,
					desc = "UI",
				},
			}
		end,
	},
}

return M
