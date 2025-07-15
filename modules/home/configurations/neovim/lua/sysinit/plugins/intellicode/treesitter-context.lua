local M = {}

M.plugins = {
	{
		"nvim-treesitter/nvim-treesitter-context",
		lazy = true,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		}, -- ensure context loads after treesitter
		config = function()
			require("treesitter-context").setup()

			vim.cmd("TSContext enable")
		end,
	},
}

return M
