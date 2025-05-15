local M = {}

M.plugins = {
	{
		enabled = true,
		"olimorris/codecompanion.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/mcphub.nvim",
		},
		config = function()
			require("codecompanion").setup({
				extensions = {
					mcphub = {
						callback = "mcphub.extensions.codecompanion",
						opts = {
							make_vars = true,
							make_slash_commands = true,
							show_result_in_chat = true,
						},
					},
				},
				strategies = {
					chat = {
						tools = {
							opts = {
								auto_submit_errors = true,
								auto_submit_success = true,
							},
						},
						keymaps = {
							send = {
								modes = {
									n = "<S-CR>",
									i = "<S-CR>",
								},
							},
						},
						opts = {
							prompt_decorator = function(message, adapter, context)
								return string.format([[<prompt>%s</prompt>]], message)
							end,
						},
					},
				},
				display = {
					action_palette = {
						provider = "telescope",
					},
					chat = {
						icons = {
							pinned_buffer = " ",
							watched_buffer = "󱣽 ",
						},
						window = {
							width = 0.33,
							position = "right",
							opts = {
								cursorline = true,
							},
						},
					},
				},
			})
		end,
		keys = {
			{
				"<leader>aa",
				"<cmd>CodeCompanionChat Toggle<cr>",
				desc = "CodeCompanion: Toggle Chat",
			},
			{
				"<leader>ai",
				"<cmd>CodeCompanion<cr>",
				desc = "CodeCompanion: Inline Assistant",
			},
			{
				"<leader>ac",
				"<cmd>CodeCompanionChat<cr>",
				desc = "CodeCompanion: Chat",
			},
			{
				"<leader>ad",
				"<cmd>CodeCompanionChat Add<cr>",
				desc = "CodeCompanion: Add Selection to Chat",
			},
			{
				"<leader>as",
				"<cmd>CodeCompanionActions<cr>",
				desc = "CodeCompanion: Actions",
			},
			{
				"<leader>am",
				"<cmd>CodeCompanionCmd<cr>",
				desc = "CodeCompanion: Command-line",
			},
		},
	},
}

return M
