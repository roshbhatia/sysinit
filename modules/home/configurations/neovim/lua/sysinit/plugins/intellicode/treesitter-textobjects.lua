local M = {}

M.plugins = {
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = {
			"BufReadPost",
			"BufNewFile",
		},
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {},
			})
		end,
	},
}

return M
