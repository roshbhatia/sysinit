local M = {}

M.plugins = {
	{
		"echasnovski/mini.surround",
		commit = "aa5e245829dd12d8ff0c96ef11da28681d6049aa",
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

