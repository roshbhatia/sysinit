local M = {}

M.plugins = {
	{
		"rmagatti/auto-session",
		lazy = false,
		opts = {
			suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
			pre_save_cmds = {
				"Neotree close",
			},
			post_restore_cmds= {
				"Neotree show"
			}
			no_restore_cmds= {
				"Alpha"
			}
			bypass_save_filetypes = { "alpha", "dashboard" },
		},
	},
}

return M

