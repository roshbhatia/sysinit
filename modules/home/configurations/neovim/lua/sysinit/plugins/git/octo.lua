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

			vim.treesitter.language.register("markdown", "octo")
		end,
		keys = function()
			return {
				{
					"<leader>grr",
					"<CMD>Octo review<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Review PR from current branch",
				},
			}
		end,
	},
}

return M
