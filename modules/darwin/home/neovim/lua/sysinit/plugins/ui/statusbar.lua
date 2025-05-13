local M = {}

M.plugins = {
	{
		"tamton-aquib/staline.nvim",
		commit = "d337bc9b343df3328921ef4c3f8ff604102d0201",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = {
			"BufEnter",
			"User AlphaClosed",
		},
		config = function()
			vim.opt.laststatus = 3

			require("staline").setup({
				sections = {
					left = { " ", "mode", " ", "branch", " ", "lsp", " " },
					mid = {},
					right = { "cool_symbol", "file_name", "line_column" },
				},
				mode_colors = {
					i = "#c6a0f6", -- Mauve
					n = "#8aadf4", -- Blue
					c = "#a6da95", -- Green
					v = "#f5a97f", -- Peach
				},
				defaults = {
					true_colors = true,
					line_column = " [%l/%L] :%c  ",
					branch_symbol = " ",
				},
			})
		end,
	},
}

return M

