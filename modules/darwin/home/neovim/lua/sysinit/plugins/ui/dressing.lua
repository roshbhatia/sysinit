local M = {}

M.plugins = {
	{
		"stevearc/dressing.nvim",
		lazy = true,
		dependencies = { "MunifTanjim/nui.nvim", "nvim-telescope/telescope.nvim" },
		opts = {
			input = {
				enabled = true,
				default_prompt = "Input:",
				title_pos = "left",
				insert_only = true,
				start_in_insert = true,
				border = "rounded",
				relative = "cursor",
				prefer_width = 40,
				width = nil,
				max_width = { 140, 0.9 },
				min_width = { 20, 0.2 },
				win_options = {
					winblend = 0,
					wrap = false,
				},
			},
			select = {
				enabled = true,
				backend = { "telescope", "fzf", "builtin", "nui" },
				trim_prompt = true,
			},
		},
	},
}

return M
