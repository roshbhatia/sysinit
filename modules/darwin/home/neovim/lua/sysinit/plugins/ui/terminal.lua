local M = {}

M.plugins = {
	{
		"voldikss/vim-floaterm",
		version = "*",
		cmd = {
			"FloatermNew",
			"FloatermToggle",
			"FloatermKill",
			"FloatermSend",
			"FloatermShow",
			"FloatermHide",
			"FloatermPrev",
			"FloatermNext",
			"FloatermFirst",
			"FloatermLast",
			"FloatermUpdate",
		},
		keys = {
			{
				"<leader>tt",
				"<cmd>FloatermToggle --width=0.8 --height=0.8 --name=terminal<CR>",
				desc = "Terminal: Toggle floating terminal",
			},
		},
	},
}

return M

