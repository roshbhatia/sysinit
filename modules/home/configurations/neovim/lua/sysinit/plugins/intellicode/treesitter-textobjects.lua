local M = {}

M.plugins = {
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		event = "BufReadPre",
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {},
			})
		end,
	},
}

return M

