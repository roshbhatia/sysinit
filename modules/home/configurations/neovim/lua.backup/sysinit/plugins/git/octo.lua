local M = {}

M.plugins = {
	{
		"pwntester/octo.nvim",
		event = "VeryLazy",
		requires = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("octo").setup({
				use_local_fs = true,
				enable_builtin = true,
			})
		end,
	},
}

return M
