local M = {}

M.plugins = {
	{
		"mfussenegger/nvim-dap",
		commit = "8df427aeba0a06c6577dc3ab82de3076964e3b8d",
		lazy = false,
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Debugger: Toggle breakpoint",
			},

			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Debugger: Continue",
			},

			{
				"<leader>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Debugger: Run to cursor",
			},

			{
				"<leader>dT",
				function()
					require("dap").terminate()
				end,
				desc = "Debugger: Terminate",
			},
		},
	},
}

return M

