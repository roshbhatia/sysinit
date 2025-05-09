local M = {}

M.plugins = {
	{
		"tamton-aquib/staline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "xiyaowong/transparent.nvim" },
		event = "User AlphaClosed",
		config = function()
			vim.opt.laststatus = 3

			require("staline").setup({
				sections = {
					left = { " ", "mode", " ", "branch", " ", "lsp" },
					mid = {},
					right = { "file_name", "line_column" },
				},
				defaults = {
					true_colors = true,
					line_column = " [%l/%L] :%c  ",
					branch_symbol = " ",
				},
			})

			require("transparent").clear_prefix("Staline")
		end,
	},
}

return M
