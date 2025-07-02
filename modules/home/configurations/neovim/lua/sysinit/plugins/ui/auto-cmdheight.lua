local M = {}

M.plugins = {
	{
		"jake-stewart/auto-cmdheight.nvim",
		lazy = false,
		opts = {
			max_lines = 0,
			duration = 0,
			remove_on_key = true,
			clear_always = true,
		},
	},
}

return M
