local M = {}

M.plugins = {
	{
		"rmagatti/auto-session",
		lazy = false,
		opts = {
			suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
			bypass_save_filetypes = { "alpha", "dashboard" },
			git_use_branch_name = true,
			session_lens = {
				load_on_setup = true,
				previewer = true,
			},
			previewer = true,
			restore_error_handler = function() end, -- ignore errors on restore
		},
	},
}

return M
