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
				"<leader>dt",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Debugger: Run to cursor",
			},
			{
				"<leader>dB",
				function()
					require("dap").clear_breakpoints()
				end,
				desc = "Debugger: Clear breakpoints",
			},
			{
				"<leader>dr",
				function()
					require("dap").run()
				end,
				desc = "Debugger: Run",
			},
			{
				"<leader>dD",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Debugger: Toggle REPL",
			},
			{
				"<leader>dR",
				function()
					require("dap").restart()
				end,
				desc = "Debugger: Restart",
			},
			{
				"<leader>dx",
				function()
					require("dap").terminate()
				end,
				desc = "Debugger: Terminate",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Debugger: Step into",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Debugger: Step over",
			},
		},
	},
}

return M
