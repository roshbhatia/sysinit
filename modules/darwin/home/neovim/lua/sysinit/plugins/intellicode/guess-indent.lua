local M = {}

M.plugins = {
	{
		"NMAC427/guess-indent.nvim",
		event = "BufReadPre",
		opts = {
			filetype_exclude = {
				"netrw",
				"help",
				"terminal",
				"prompt",
				"TelescopePrompt",
				"mason",
				"lspinfo",
				"packer",
				"checkhealth",
				"help",
				"man",
				"git",
				"fugitive",
			},
			buftype_exclude = { "help", "nofile", "terminal", "prompt", "neo-tree" },
		},
	},
}

return M
