local M = {}

M.plugins = {
	{
		"tpope/vim-fugitive",
		branch = "master",
		cmd = { "Git", "Gvdiffsplit" },
		keys = {
			{
				"<leader>gs",
				"<CMD>Git<CR>",
				desc = "Open git status",
			},
			{
				"<leader>gc",
				"<CMD>Git commit<CR>",
				desc = "Commit",
			},
			{
				"<leader>gP",
				"<CMD>Git push<CR>",
				desc = "Push",
			},
			{
				"<leader>gp",
				"<CMD>Git pull<CR>",
				desc = "Pull",
			},
			{
				"<leader>gl",
				"<CMD>Git log<CR>",
				desc = "Log",
			},
			{
				"<leader>gbd",
				"<CMD>Gvdiffsplit!<CR>",
				desc = "Diff buffer",
			},
			{
				"<leader>gbD",
				"<CMD>Gvdiffsplit! HEAD^ HEAD~1<CR>",
				desc = "Diff buffer with previous commit",
			},
		},
	},
}

return M
