local M = {}

M.plugins = {
	{
		"NMAC427/guess-indent.nvim",
		lazy = false,
		opts = {
			auto_cmd = true,
			override_editorconfig = false,
			filetype_exclude = {
				"netrw",
				"help",
				"terminal",
				"prompt",
				"neo-tree",
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
			buftype_exclude = { "help", "nofile", "terminal", "prompt" },
			on_tab_options = {
				expandtab = false,
				tabstop = 4,
				shiftwidth = 4,
				softtabstop = 0,
			},
			on_space_options = {
				expandtab = true,
				tabstop = "detected",
				shiftwidth = "detected",
				softtabstop = "detected",
			},
		},
	},
}

return M
