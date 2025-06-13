local M = {}
M.plugins = {
	{
		"aweis89/ai-terminals.nvim",
		dependencies = {
			"folke/snacks.nvim",
		},
		event = "VeryLazy",
		opts = {
			terminals = {
				goose = {
					cmd = function()
						return string.format("GOOSE_CLI_THEME=%s goose", vim.o.background)
					end,
				},
				aider = {
					cmd = function()
						return string.format("aider --watch-files --%s-mode", vim.o.background)
					end,
				},
			},
			default_position = "float",
			window_dimensions = {
				float = { width = 0.8, height = 0.7 },
				bottom = { width = 1.0, height = 0.4 },
				border = "rounded",
			},
			enable_diffing = true,
			show_diffs_on_leave = true,
		},
		keys = function()
			return {
				{
					"<leader>aa",
					function()
						require("ai-terminals").toggle("goose")
					end,
					mode = { "n", "v" },
					desc = "Toggle Goose chat (sends selection in visual mode)",
				},
				{
					"<leader>aA",
					function()
						require("ai-terminals").toggle("aider")
					end,
					mode = { "n", "v" },
					desc = "Toggle Aider session (sends selection in visual mode)",
				},
				{
					"<leader>at",
					function()
						require("ai-terminals").focus()
					end,
					desc = "Focus last used AI terminal",
				},
				{
					"<leader>aq",
					function()
						require("ai-terminals").destroy_all()
					end,
					desc = "Close all AI terminals",
				},
				{
					"<leader>af",
					function()
						-- Focus and maximize the current terminal
						require("ai-terminals").focus()
					end,
					desc = "Focus terminal (fullscreen effect)",
				},
				{
					"<leader>as",
					function()
						vim.ui.select({ "goose", "aider" }, {
							prompt = "Select AI Terminal:",
						}, function(choice)
							if choice then
								require("ai-terminals").toggle(choice)
							end
						end)
					end,
					desc = "Select AI terminal session",
				},
				{
					"<leader>ap",
					function()
						require("ai-terminals").send_diagnostics()
					end,
					mode = { "n", "v" },
					desc = "Send diagnostics to active AI terminal",
				},
				{
					"<leader>ad",
					function()
						require("ai-terminals").diff_changes()
					end,
					desc = "Show diff (vimdiff)",
				},
				{
					"<leader>an",
					function()
						require("ai-terminals").diff_changes({ delta = true })
					end,
					desc = "Show diff (delta view)",
				},
				{
					"<leader>aN",
					function()
						require("ai-terminals").diff_changes()
					end,
					desc = "Show diff (vimdiff)",
				},
				{
					"<leader>ac",
					function()
						require("ai-terminals").close_diff()
					end,
					desc = "Close diff view",
				},
				{
					"<leader>aU",
					function()
						require("ai-terminals").revert_changes()
					end,
					desc = "Revert changes from backup",
				},
				{
					"<leader>aR",
					function()
						require("ai-terminals").destroy_all()
						vim.defer_fn(function()
							require("ai-terminals").toggle("goose")
						end, 100)
					end,
					desc = "Reset chat (restart terminals)",
				},
				{
					"<leader>ar",
					function()
						require("ai-terminals").send_command_output()
					end,
					desc = "Run command and send output to AI terminal",
				},
				{
					"<leader>al",
					function()
						require("ai-terminals").aider_add_files(vim.fn.expand("%"))
					end,
					desc = "Add current file to Aider",
				},
				{
					"<leader>aC",
					function()
						require("ai-terminals").aider_comment("AI!")
					end,
					desc = "Add AI comment above line",
				},
				{
					"<leader>adg",
					function()
						require("ai-terminals").send_diagnostics("goose")
					end,
					mode = { "n", "v" },
					desc = "Send diagnostics to Goose",
				},
				{
					"<leader>ada",
					function()
						require("ai-terminals").send_diagnostics("aider")
					end,
					mode = { "n", "v" },
					desc = "Send diagnostics to Aider",
				},
			}
		end,
	},
}
return M

