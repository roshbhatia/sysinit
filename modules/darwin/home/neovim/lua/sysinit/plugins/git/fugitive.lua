-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/tpope/vim-fugitive/refs/heads/master/doc/fugitive.txt"
local M = {}

M.plugins = {
	{
		"tpope/vim-fugitive",
		lazy = false,
		keys = {
			{
				"<leader>gs",
				"<cmd>Git<CR>",
				desc = "Git: open git status",
			},
			{
				"<leader>gc",
				"<cmd>Git commit<CR>",
				desc = "Git: commit",
			},
			{
				"<leader>gp",
				"<cmd>Git push<CR>",
				desc = "Git: push",
			},
			{
				"<leader>gP",
				"<cmd>Git pull<CR>",
				desc = "Git: pull",
			},
			{
				"<leader>gl",
				"<cmd>Git log<CR>",
				desc = "Git: log",
			},
			{
				"<leader>gd",
				"<cmd>Gdiffsplit!<CR>",
				desc = "Git: diff split",
			},
			{
				"<leader>gD",
				"<cmd>Gdiffsplit! HEAD^ HEAD~1<CR>",
				desc = "Git: diff split previous commit",
			},
		},
	},
}

return M
