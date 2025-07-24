local M = {}

M.plugins = {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
		},
		config = function()
			vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
		end,
		keys = {
			{
				"<localleader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle breakpoint",
			},
			{
				"<localleader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue",
			},
			{
				"<localleader>dt",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to cursor",
			},
			{
				"<localleader>dB",
				function()
					require("dap").clear_breakpoints()
				end,
				desc = "Clear breakpoints",
			},
			{
				"<localleader>dr",
				function()
					require("dap").run()
				end,
				desc = "Run",
			},
			{
				"<localleader>dD",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
			{
				"<localleader>dR",
				function()
					require("dap").restart()
				end,
				desc = "Restart",
			},
			{
				"<localleader>dx",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
			{
				"<localleader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step into",
			},
			{
				"<localleader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Step over",
			},
		},
	},
}

return M

