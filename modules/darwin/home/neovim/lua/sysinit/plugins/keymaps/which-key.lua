local M = {}

M.plugins = {
	{
		"Cassin01/wf.nvim",
		version = "*",
		config = function()
			require("wf").setup()
			local which_key = require("wf.builtin.which_key")

			vim.keymap.set(
				"n",
				"<Leader>",
				-- mark(opts?: table) -> function
				-- opts?: option
				which_key({ text_insert_in_advance = "<Leader>" }),
				{ noremap = true, silent = true, desc = "[wf.nvim] which-key /" }
			)
		end,
	},
}

return M

