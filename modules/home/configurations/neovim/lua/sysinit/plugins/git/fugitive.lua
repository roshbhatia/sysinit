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
				desc = "Git: Open git status",
			},
			{
				"<leader>gc",
				"<cmd>Git commit<CR>",
				desc = "Git: Commit",
			},
			{
				"<leader>gP",
				"<cmd>Git push<CR>",
				desc = "Git: Push",
			},
			{
				"<leader>gp",
				"<cmd>Git pull<CR>",
				desc = "Git: Pull",
			},
			{
				"<leader>gl",
				"<cmd>Git log<CR>",
				desc = "Git: Log",
			},
			{
				"<leader>gbd",
				"<cmd>Gvdiffsplit!<CR>",
				desc = "Git: Diff buffer",
			},
			{
				"<leader>gbD",
				"<cmd>Gvdiffsplit! HEAD^ HEAD~1<CR>",
				desc = "Git: Diff buffer with previous commit",
			},
		},
	},
}

return M

