local M = {}

M.plugins = {
	{
		"folke/snacks.nvim",
		priority = 1050,
		lazy = false,
		config = function()
			require("snacks").setup({
				animate = {
					enabled = true,
					duration = 18,
					easing = "cubic",
					fps = 60,
				},
				bigfile = { enabled = true },
				bufdelete = { enabled = true },
				notifier = {
					enabled = true,
					timeout = 3000,
					level = vim.log.levels.ERROR,
					style = "minimal",
				},
				quickfile = { enabled = true },
				scroll = { enabled = true },
				statuscolumn = { enabled = true },
				words = { enabled = true },

				dashboard = { enabled = false },
				debug = { enabled = false },
				dim = { enabled = false },
				explorer = { enabled = false },
				git = { enabled = false },
				gitbrowse = { enabled = false },
				image = { enabled = false },
				indent = { enabled = false },
				input = { enabled = false },
				layout = { enabled = false },
				lazygit = { enabled = false },
				picker = { enabled = false },
				profiler = { enabled = false },
				rename = { enabled = false },
				scratch = { enabled = false },
				scope = { enabled = false },
				terminal = { enabled = false },
				toggle = { enabled = false },
				win = { enabled = false },
				zen = { enabled = false },
			})

			vim.api.nvim_create_autocmd("LspProgress", {
				---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
				callback = function(ev)
					local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
					vim.notify(vim.lsp.status(), "info", {
						id = "lsp_progress",
						title = "LSP Progress",
						opts = function(notif)
							notif.icon = ev.data.params.value.kind == "end" and " "
								---@diagnostic disable-next-line: undefined-field
								or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
						end,
					})
				end,
			})
		end,
		keys = function()
			return {
				{
					"<leader>ns",
					function()
						Snacks.notifier.show_history()
					end,
					desc = "Notifications: Show",
				},
				{
					"<leader>nc",
					function()
						Snacks.notifier.hide()
					end,
					desc = "Notifications: Dismiss",
				},
			}
		end,
	},
}

return M

