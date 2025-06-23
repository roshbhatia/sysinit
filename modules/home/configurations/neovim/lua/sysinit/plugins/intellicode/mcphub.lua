local M = {}

M.plugins = {
	{
		enabled = not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot")),
		"ravitemer/mcphub.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("mcphub").setup({
				extensions = {
					avante = {
						make_slash_commands = true,
					},
				},
			})
		end,
	},
}

return M
