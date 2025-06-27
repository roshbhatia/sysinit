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
				aichat = nil,
				claude = nil,
				codex = nil,
				gemini = nil,
			},
			default_position = "right",
			env = {
				PAGER = "bat",
			},
		},
		keys = function()
			return {
				{
					"<leader>tgc",
					function()
						require("ai-terminals").toggle("goose")
					end,
					mode = { "n", "v" },
					desc = "Toggle Goose chat (sends selection in visual mode)",
				},
				{
					"<leader>tac",
					function()
						require("ai-terminals").toggle("aider")
					end,
					mode = { "n", "v" },
					desc = "Toggle Aider chat (sends selection in visual mode)",
				},
				{
					"<leader>tgd",
					function()
						require("ai-terminals").send_diagnostics("goose")
					end,
					mode = { "n", "v" },
					desc = "Send diagnostics to Goose",
				},
				{
					"<leader>tad",
					function()
						require("ai-terminals").send_diagnostics("aider")
					end,
					mode = { "n", "v" },
					desc = "Send diagnostics to Aider",
				},
				{
					"<leader>tx",
					function()
						require("ai-terminals").destroy_all()
					end,
					desc = "Close all AI terminals",
				},
				{
					"<leader>td",
					function()
						require("ai-terminals").diff_changes({ delta = true })
					end,
					desc = "Show diff",
				},
				{
					"<leader>tR",
					function()
						require("ai-terminals").revert_changes()
					end,
					desc = "Revert diff",
				},
				{
					"<leader>taa",
					function()
						require("ai-terminals").aider_comment("AI!")
					end,
					desc = "Add 'AI!' comment above line",
				},
				{
					"<leader>taA",
					function()
						require("ai-terminals").aider_comment("AI?")
					end,
					desc = "Add 'AI?' comment above line",
				},
				{
					"<leader>taf",
					function()
						require("ai-terminals").aider_add_files(vim.fn.expand("%"))
					end,
					desc = "Add current file to Aider (/add)",
				},
				{
					"<leader>tab",
					function()
						require("ai-terminals").aider_add_buffers()
					end,
					desc = "Add all listed buffers to Aider",
				},
				{
					"<leader>tf",
					function()
						require("ai-terminals").focus()
					end,
					desc = "Focus the last used AI terminal window",
				},
			}
		end,
	},
}

return M
