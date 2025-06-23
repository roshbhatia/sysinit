local M = {}

M.plugins = {
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = {
			"VeryLazy",
		},
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("treesitter-context").setup()

			vim.cmd("TSContext enable")
		end,
	},
}

return M

