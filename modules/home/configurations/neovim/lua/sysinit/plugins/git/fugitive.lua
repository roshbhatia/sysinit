local M = {}

M.plugins = {
	{
		"tpope/vim-fugitive",
		branch = "master",
		cmd = {
			"Git",
			"Gvdiffsplit",
		},
		keys = {
			{
				"<localleader>gs",
				"<CMD>Git<CR>",
				desc = "Open git status",
			},
			{
				"<localleader>gc",
				"<CMD>Git commit<CR>",
				desc = "Commit",
			},
			{
				"<localleader>gP",
				"<CMD>Git push<CR>",
				desc = "Push",
			},
			{
				"<localleader>gp",
				"<CMD>Git pull<CR>",
				desc = "Pull",
			},
			{
				"<localleader>gl",
				"<CMD>Git log<CR>",
				desc = "Log",
			},
			{
				"<localleader>gbd",
				"<CMD>Gvdiffsplit!<CR>",
				desc = "Diff buffer",
			},
			{
				"<localleader>gbD",
				"<CMD>Gvdiffsplit! HEAD^ HEAD~1<CR>",
				desc = "Diff buffer with previous commit",
			},
		},
	},
}

return M
