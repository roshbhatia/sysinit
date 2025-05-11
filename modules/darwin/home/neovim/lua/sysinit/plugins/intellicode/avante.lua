local M = {}

M.plugins = {
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		build = ":AvanteBuild",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim",
			"hrsh7th/nvim-cmp",
			"nvim-tree/nvim-web-devicons",
			"zbirenbaum/copilot.lua",
			"MeanderingProgrammer/render-markdown.nvim",
		},
		config = function()
			local avante = require("avante")
			avante.setup({
				provider = "copilot",
				mode = "legacy",
				auto_suggestions_provider = "copilot",
				copilot = {
					model = "claude-3.5-sonnet",
				},
				behaviour = {
					auto_suggestions = false,
					auto_apply_diff_after_generation = true,
					support_paste_from_clipboard = true,
				},
				mappings = {
					submit = {
						normal = "<CR>",
						insert = "<S-CR>",
					},
				},
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "PersistenceSavePre",
				callback = function()
					avante.close_sidebar()
				end,
			})
		end,
	},
}

return M
