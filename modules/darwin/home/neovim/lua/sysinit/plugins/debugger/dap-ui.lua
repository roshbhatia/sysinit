local M = {}

M.plugins = {
	{
		"rcarriga/nvim-dap-ui",
		lazy = true,
		event = "VeryLazy",
		dependencies = { "nvim-neotest/nvim-nio", "mfussenegger/nvim-dap" },
		keys = function()
			return {
				{
					"<leader>dd",
					function()
						require("dapui").toggle({})
					end,
					desc = "Debugger: Toggle UI",
				},
				{
					"<leader>dw",
					function()
						require("dap.ui.widgets").hover()
					end,
					desc = "Debugger: Widgets",
				},
				{
					"<leader>db",
					function()
						require("dap").toggle_breakpoint()
					end,
					desc = "Debugger: Toggle breakpoint",
				},
				{
					"<leader>dl",
					function()
						require("dap").run_last()
					end,
					desc = "Debugger: Run last debug",
				},
				{
					"<leader>dt",
					function()
						require("dap").terminate()
					end,
					desc = "Debugger: Terminate",
				},
				{
					"<leader>dr",
					function()
						require("dap").continue()
					end,
					desc = "Debugger: Continue debugging",
				},
				{
					"<leader>dsv",
					function()
						require("dap").step_over()
					end,
					desc = "Debugger: Step over",
				},
				{
					"<leader>dsi",
					function()
						require("dap").step_into()
					end,
					desc = "Debugger: Step into",
				},
				{
					"<leader>dso",
					function()
						require("dap").step_out()
					end,
					desc = "Debugger: Step out",
				},
				{
					"<leader>dc",
					function()
						require("dap").run_to_cursor()
					end,
					desc = "Debugger: Run to Cursor",
				},
				{
					"<leader>dg",
					function()
						require("dap").goto_()
					end,
					desc = "Debugger: Go to Line (No Execute)",
				},
				{
					"<leader>dj",
					function()
						require("dap").down()
					end,
					desc = "Debugger: Down",
				},
				{
					"<leader>dk",
					function()
						require("dap").up()
					end,
					desc = "Debugger: Up",
				},
			}
		end,
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end

			vim.api.nvim_create_user_command("DapUIToggle", function()
				dapui.toggle()
			end, {})
			vim.api.nvim_create_user_command("DapUIFloat", function()
				dapui.float_element("scopes")
			end, {})
		end,
	},
}

return M
