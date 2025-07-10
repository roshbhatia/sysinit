local M = {}

M.plugins = {
	{
		"olimorris/codecompanion.nvim",
		opts = {
			strategies = {
				chat = {
					adapter = "copilot",
				},
				inline = {
					adapter = "copilot",
				},
			},
			display = {
				chat = {
					window = {
						layout = "vertical",
						width = 0.45,
						height = 0.8,
						border = "rounded",
					},
				},
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		keys = function()
			return {
				{
					"<leader>kk",
					"<CMD>CodeCompanionChat toggle<CR>",
					desc = "Toggle chat",
					mode = { "n", "v" },
				},
				{
					"<leader>kK",
					"<CMD>CodeCompanionChat<CR>",
					desc = "New chat",
					mode = { "n", "v" },
				},
				{
					"<leader>ke",
					"<CMD>CodeCompanion<CR>",
					desc = "Inline assistant",
					mode = { "n", "v" },
				},
				{
					"<leader>ka",
					"<CMD>CodeCompanionActions<CR>",
					desc = "Action palette",
					mode = { "n", "v" },
				},
				{
					"<leader>kt",
					"<CMD>CodeCompanionChat Toggle<CR>",
					desc = "Toggle chat",
					mode = "n",
				},
				{
					"<leader>kc",
					"<CMD>CodeCompanionChat Add<CR>",
					desc = "Add current file to chat",
					mode = { "n", "v" },
				},
				{
					"<leader>k/",
					"<CMD>CodeCompanion /explain<CR>",
					desc = "Explain code",
					mode = "v",
				},
				{
					"<leader>k.",
					"<CMD>CodeCompanion /fix<CR>",
					desc = "Fix code",
					mode = "v",
				},
				{
					"<leader>k,",
					"<CMD>CodeCompanion /tests<CR>",
					desc = "Generate tests",
					mode = "v",
				},
				{
					"<leader>kl",
					"<CMD>CodeCompanion /lsp<CR>",
					desc = "Explain LSP diagnostics",
					mode = "v",
				},
				{
					"<leader>k:",
					"<CMD>CodeCompanionCmd<CR>",
					desc = "Generate command",
					mode = "n",
				},
			}
		end,
	},
}
return M
