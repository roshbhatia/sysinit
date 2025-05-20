local M = {}

M.plugins = {
	{
		"rmagatti/auto-session",
		lazy = false,
		opts = {
			suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
			post_restore_cmds = {
				"Silent Neotree show",
			},
			bypass_save_filetypes = { "alpha", "dashboard" },
			git_use_branch_name = true,
			session_lens = {
				previewer = true,
			},
		},
	},
}

return M

