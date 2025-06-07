local M = {}

M.plugins = {
	{
		"jake-stewart/auto-cmdheight.nvim",
		lazy = false,
		opts = {
			max_lines = 5,
			duration = 2,
			remove_on_key = true,
			clear_always = false,
		},
	},
}

return M

