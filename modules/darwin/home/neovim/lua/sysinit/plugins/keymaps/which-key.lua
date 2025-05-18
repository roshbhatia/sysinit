local M = {}

M.plugins = {
	{
		"Cassin01/wf.nvim",
		version = "*",
		config = function()
			require("wf").setup()
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

