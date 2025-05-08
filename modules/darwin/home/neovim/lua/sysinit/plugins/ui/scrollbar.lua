local M = {}

M.plugins = {
	{
		"petertriho/nvim-scrollbar",
		lazy = false,
		opts = {
			show = true,
			handle = {
				text = " ",
				color = "ScrollbarHandle",
				hide_if_all_visible = true,
			},
			marks = {},
			excluded_filetypes = { "prompt", "TelescopePrompt", "noice", "neo-tree", "alpha" },
			autocmd = {
				render = {
					"BufWinEnter",
					"TabEnter",
					"TermEnter",
					"WinEnter",
					"CmdwinLeave",
					"TextChanged",
					"VimResized",
					"WinScrolled",
				},
			},
		},
	},
}

return M
