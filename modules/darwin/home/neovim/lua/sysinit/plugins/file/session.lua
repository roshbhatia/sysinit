local M = {}

M.plugins = {
	{
		"olimorris/persisted.nvim",
		event = "BufReadPre",
		opts = {
			use_git_branch = true,
			autoload = true,
			on_autoload_no_session = function()
				vim.cmd("Alpha")
			end,
		},
	},
}

return M
