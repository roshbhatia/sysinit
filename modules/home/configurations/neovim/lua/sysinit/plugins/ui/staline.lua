local M = {}

M.plugins = {
	{
		"tamton-aquib/staline.nvim",
		commit = "d337bc9b343df3c28921ef4c3f8ff604102d0201",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = {
			"BufEnter",
			"User AlphaClosed",
		},
		config = function()
			vim.opt.laststatus = 3

			require("staline").setup({
				sections = {
					left = { "mode", "branch", " ", "lsp" },
					mid = { "lsp_name" },
					right = { "line_column" },
				},
				defaults = {
					expand_null_ls = true,
					true_colors = true,
					line_column = ":%c [%l/%L]",
				},
			})
		end,
	},
}

return M

