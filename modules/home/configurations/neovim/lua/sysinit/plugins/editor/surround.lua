local M = {}

M.plugins = {
	{
		"echasnovski/mini.surround",
		event = "BufReadPost",
		version = "*",
		config = function()
			require("mini.surround").setup({
				mappings = {
					add = "gsa",
					delete = "gsd",
					find = "gsf",
					highlight = "gsh",
					replace = "gsr",
					update_n_lines = "gsn",
				},
			})
		end,
	},
}

return M

