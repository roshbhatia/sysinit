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
					left = { "branch", " ", "lsp" },
					mid = { "mode" },
					right = { "line_column" },
				},
				mode_colors = {
					i = "#c6a0f6",
					n = "#8aadf4",
					c = "#a6da95",
					v = "#f5a97f",
				},
				defaults = {
					true_colors = true,
					line_column = ":%c [%l/%L]",
				},
			})
		end,
	},
}

return M
