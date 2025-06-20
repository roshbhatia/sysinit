local M = {}

M.plugins = {
	{
		"echasnovski/mini.surround",
		event = "BufReadPost",
		version = "*",
		config = function()
			require("mini.surround").setup({
				mappings = {
					add = "sa",
					delete = "sd",
					find = "sf",
					find_left = "sF",
					highlight = "sh",
					replace = "sr",
					update_n_lines = "sn",
				},
			})
		end,
	},
}

return M
