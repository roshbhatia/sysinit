local M = {}

M.plugins = {
	{
		"nvim-neotest/nvim-nio",
		lazy = false,
	},
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		event = "VeryLazy",
		config = function()
			local dap = require("dap")

			dap.adapters.python = {
				type = "executable",
				command = vim.fn.expand("$VIRTUAL_ENV/bin/python") or vim.fn.expand("$HOME/.pyenv/shims/python"),
				args = { "-m", "debugpy.adapter" },
			}

			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					pythonPath = function()
						local venv_path = os.getenv("VIRTUAL_ENV")
						return venv_path and venv_path .. "/bin/python" or vim.fn.expand("$HOME/.pyenv/shims/python")
					end,
				},
				{
					type = "python",
					request = "launch",
					name = "Launch with arguments",
					program = "${file}",
					args = function()
						return vim.split(vim.fn.input("Arguments: "), " ")
					end,
					pythonPath = function()
						local venv_path = os.getenv("VIRTUAL_ENV")
						return venv_path and venv_path .. "/bin/python" or vim.fn.expand("$HOME/.pyenv/shims/python")
					end,
				},
			}

			dap.adapters.nlua = function(callback, config)
				callback({
					type = "server",
					host = config.host or "127.0.0.1",
					port = config.port or 8086,
				})
			end
			dap.configurations.lua = {
				{
					type = "nlua",
					request = "attach",
					name = "Attach to running Neovim instance",
					host = function()
						return "127.0.0.1"
					end,
					port = function()
						return 8086
					end,
				},
			}

			dap.adapters.node2 = {
				type = "executable",
				command = "node",
				args = { vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
			}

			dap.configurations.javascript = {
				{
					name = "Launch",
					type = "node2",
					request = "launch",
					program = "${file}",
					cwd = vim.fn.getcwd(),
					sourceMaps = true,
					protocol = "inspector",
					console = "integratedTerminal",
				},
				{
					name = "Attach to process",
					type = "node2",
					request = "attach",
					processId = require("dap.utils").pick_process,
				},
			}

			dap.configurations.typescript = dap.configurations.javascript

			vim.api.nvim_create_user_command("DapToggleBreakpoint", function()
				dap.toggle_breakpoint()
			end, {})
			vim.api.nvim_create_user_command("DapContinue", function()
				dap.continue()
			end, {})
			vim.api.nvim_create_user_command("DapStepOver", function()
				dap.step_over()
			end, {})
			vim.api.nvim_create_user_command("DapStepInto", function()
				dap.step_into()
			end, {})
			vim.api.nvim_create_user_command("DapStepOut", function()
				dap.step_out()
			end, {})
			vim.api.nvim_create_user_command("DapTerminate", function()
				dap.terminate()
			end, {})

			vim.fn.sign_define("DapBreakpoint", {
				text = "",
				texthl = "DiagnosticSignError",
				linehl = "",
				numhl = "",
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "dap-repl",
				callback = function()
					require("dap.ext.autocompl").attach()
				end,
			})

			dap.defaults.fallback.terminal_win_cmd = "50vsplit new"
		end,
	},
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
