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
				{
					"<leader>grs",
					"<CMD>Octo review submit<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Submit PR review",
				},
				{
					"<leader>grb",
					"<CMD>Octo review browse<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Browse PR review",
				},

				{
					"<leader>grp",
					"<CMD>Octo pr list<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "List PRs",
				},
				{
					"<leader>gre",
					"<CMD>Octo pr edit<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Edit current PR",
				},

				{
					"<leader>grc",
					"<CMD>Octo comment add<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Add comment",
				},
				{
					"<leader>grg",
					"<CMD>Octo comment suggest<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Add suggestion",
				},
				{
					"<leader>grd",
					"<CMD>Octo thread resolve<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Resolve thread",
				},
				{
					"<leader>gru",
					"<CMD>Octo thread unresolve<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Unresolve thread",
				},

				{
					"<leader>gr+",
					"<CMD>Octo reaction thumbs_up<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Add 👍 reaction",
				},
				{
					"<leader>gr:",
					"<CMD>Octo reaction eyes<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Add 👀 reaction",
				},
			}
		end,
	},
}

return M

