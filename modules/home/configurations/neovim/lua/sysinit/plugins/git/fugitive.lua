local M = {}

M.plugins = {
	{
		"tpope/vim-fugitive",
		branch = "master",
		cmd = { "Git", "Gvdiffsplit" },
		keys = {
			{
				"<leader>gs",
				"<cmd>Git<CR>",
				desc = "Open git status",
			},
			{
				"<leader>gc",
				"<cmd>Git commit<CR>",
				desc = "Commit",
			},
			{
				"<leader>gP",
				"<cmd>Git push<CR>",
				desc = "Push",
			},
			{
				"<leader>gp",
				"<cmd>Git pull<CR>",
				desc = "Pull",
			},
			{
				"<leader>gl",
				"<cmd>Git log<CR>",
				desc = "Log",
			},
			{
				"<leader>gbd",
				"<cmd>Gvdiffsplit!<CR>",
				desc = "Diff buffer",
			},
			{
				"<leader>gbD",
				"<cmd>Gvdiffsplit! HEAD^ HEAD~1<CR>",
				desc = "Diff buffer with previous commit",
			},
		},
	},
}

return M

