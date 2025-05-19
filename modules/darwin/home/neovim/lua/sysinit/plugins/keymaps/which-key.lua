local M = {}

M.plugins = {
	{
		"Cassin01/wf.nvim",
		version = "*",
		config = function()
			require("wf").setup()
		end,
		keys = function()
			local which_key = require("wf.builtin.which_key")

			return {
				{
					"<leader>",
					which_key({
						text_insert_in_advance = "<Space>",
					}),
					{
						noremap = true,
						silent = true,
						desc = "[wf.nvim] which-key /",
					},
				},
			}
		end,
	},
}

return M
