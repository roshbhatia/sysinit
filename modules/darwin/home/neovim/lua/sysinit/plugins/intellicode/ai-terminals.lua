return {
	{
		"aweis89/ai-terminals.nvim",
		enabled = true,
		event = "VeryLazy",
		dependencies = { "folke/snacks.nvim" },
		config = function()
			require("ai-terminals").setup({
				terminals = {
					goose = {
						cmd = function()
							return "GOOSE_CLI_THEME=dark goose"
						end,
					},
					aider = nil,
					claude = nil,
					aichat = nil,
					kode = nil,
				},
				default_position = "right",
				enable_diffing = true,
				show_diffs_on_leave = { delta = true },
				prompt_keymaps = {
					{
						key = "<leader>ae",
						term = "goose",
						prompt = "Explain the selected code snippet.",
						desc = "Copilot: Explain selection",
						include_selection = true,
						submit = true,
					},
					{
						key = "<leader>as",
						term = "goose",
						prompt = function()
							local file_path = vim.fn.expand("%:p")
							return string.format("Summarize the content of the file: `%s`", file_path)
						end,
						desc = "Copilot: Summarize current file",
						include_selection = false,
						submit = true,
					},
				},
			})
		end,
		keys = function()
			return {
				{
					"<leader>aa",
					function()
						require("ai-terminals").toggle("goose")
					end,
					desc = "Copilot: Toggle chat",
					mode = { "n", "v" },
				},
				{
					"<leader>aA",
					function()
						require("ai-terminals").send_command_output("goose")
					end,
					desc = "Copilot: Open a new chat session",
					mode = { "n" },
				},
				{
					"<leader>ad",
					function()
						require("ai-terminals").send_diagnostics("goose")
					end,
					desc = "Copilot: Send diagnostics to chat",
					mode = { "n", "v" },
				},
				{
					"<leader>af",
					function()
						require("ai-terminals").focus()
					end,
					desc = "Copilot: Focus the chat",
					mode = { "n" },
				},
				{
					"<leader>ax",
					function()
						require("ai-terminals").destroy_all()
					end,
					desc = "Destroy all AI terminals",
					mode = { "n" },
				},
			}
		end,
	},
}
