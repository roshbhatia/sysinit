-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/tpope/vim-fugitive/refs/heads/master/doc/fugitive.txt"
local M = {}

M.plugins = {
	{
		"tpope/vim-fugitive",
		event = "VeryLazy",
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
				"<leader>gp",
				"<cmd>Git push<CR>",
				desc = "Git: Push",
			},
			{
				"<leader>gP",
				"<cmd>Git pull<CR>",
				desc = "Git: Pull",
			},
			{
				"<leader>gl",
				"<cmd>Git log<CR>",
				desc = "Git: Log",
			},
			{
				"<leader>gd",
				"<cmd>Gdiffsplit!<CR>",
				desc = "Git: Diff split",
			},
			{
				"<leader>gD",
				"<cmd>Gdiffsplit! HEAD^ HEAD~1<CR>",
				desc = "Git: Diff split previous commit",
			},
		},
	},
}

return M
