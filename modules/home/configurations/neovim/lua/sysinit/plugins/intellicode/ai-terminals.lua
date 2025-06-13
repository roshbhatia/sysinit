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
			default_position = "right",
		},
		keys = function()
			return {
				{
					"<leader>aag",
					function()
						require("ai-terminals").toggle("goose")
					end,
					mode = { "n", "v" },
					desc = "Toggle Goose chat (sends selection in visual mode)",
				},
				{
					"<leader>aaa",
					function()
						require("ai-terminals").toggle("aider")
					end,
					mode = { "n", "v" },
					desc = "Toggle Aider session (sends selection in visual mode)",
				},
				{
					"<leader>aa<leader>",
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
					"<leader>ad",
					function()
						require("ai-terminals").diff_changes({ delta = true })
					end,
					desc = "Show diff (delta view)",
				},
				{
					"<leader>ac",
					function()
						require("ai-terminals").close_diff()
					end,
					desc = "Close diff view",
				},
				{
					"<leader>al",
					function()
						require("ai-terminals").aider_add_files(vim.fn.expand("%"))
					end,
					desc = "Add current file to Aider",
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
