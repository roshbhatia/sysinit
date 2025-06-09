local M = {}

M.plugins = {
	{
		enabled = not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot")),
		"giuxtaposition/blink-cmp-copilot",
		dependencies = {
			"zbirenbaum/copilot.lua",
		},
	},
}

return M
