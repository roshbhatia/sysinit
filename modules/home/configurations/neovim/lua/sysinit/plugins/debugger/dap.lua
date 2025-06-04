local M = {}

M.plugins = {
	{
		"mfussenegger/nvim-dap",
		commit = "8df427aeba0a06c6577dc3ab82de3076964e3b8d",
		lazy = false,
		recommended = true,
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"jay-babu/mason-nvim-dap.nvim",
		},
		config = function()
			vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
		end,
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue",
			},
			{
				"<leader>dt",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to cursor",
			},
			{
				"<leader>dB",
				function()
					require("dap").clear_breakpoints()
				end,
				desc = "Clear breakpoints",
			},
			{
				"<leader>dr",
				function()
					require("dap").run()
				end,
				desc = "Run",
			},
			{
				"<leader>dD",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
			{
				"<leader>dR",
				function()
					require("dap").restart()
				end,
				desc = "Restart",
			},
			{
				"<leader>dx",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step into",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Step over",
			},
		},
	},
}

return M

