local M = {}

M.plugins = {
	{
		"voldikss/vim-floaterm",
		version = "*",
		cmd = {
			"FloatTermNew", "FloatermToggle", "FloatermKill", "FloatTermSend", "FloatTermShow", "FloatTermHide", "FloatTermPrev", "FloatTermNext", "FloatTermFirst", "FloatTermLast", "FloatTermUpdate"
		},
		keys = {
			{
				"<leader>tt",
				"<cmd>FloatermToggle<CR>",
				desc = "Terminal: Toggle floating terminal",
			},
		},
}

return M

