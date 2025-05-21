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
						desc = "Goose: Explain selection",
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
						desc = "Goose: Summarize current file",
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
					desc = "Toggle Goose terminal",
					mode = { "n", "v" },
				},
				{
					"<leader>aA",
					function()
						require("ai-terminals").send_command_output("goose")
					end,
					desc = "Open a new Goose terminal session",
					mode = { "n" },
				},
				{
					"<leader>ad",
					function()
						require("ai-terminals").send_diagnostics("goose")
					end,
					desc = "Send diagnostics to Goose terminal",
					mode = { "n", "v" },
				},
				{
					"<leader>af",
					function()
						require("ai-terminals").focus()
					end,
					desc = "Focus the Goose terminal",
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

