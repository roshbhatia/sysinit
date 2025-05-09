local M = {}

M.plugins = {
	{
		"f-person/git-blame.nvim",
		event = "VeryLazy",
		opts = {
			enabled = true,
			message_template = "  <summary> by <author> in <<sha>>",
			date_format = "%m-%d-%Y",
			virtual_text_column = 1,
		},
	},
}

return M
