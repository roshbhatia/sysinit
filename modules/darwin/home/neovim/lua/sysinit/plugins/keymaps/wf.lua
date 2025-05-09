-- keymaps/init.lua
-- Main keymaps loader that loads and aggregates all keymap groups
local M = {}

-- Define plugins spec for lazy.nvim
M.plugins = {
	{
		"Cassin01/wf.nvim",
		version = "*",
		config = function()
			require("wf").setup({
				theme = "space",
			})
		end,
		keys = function()
			local which_key = require("wf.builtin.which_key")
			return {
				{
					"<Leader>",
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
