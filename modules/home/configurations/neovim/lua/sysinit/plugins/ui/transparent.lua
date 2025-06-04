local M = {}

M.plugins = {
	{
		"xiyaowong/transparent.nvim",
		event = "VeryLazy",
		keys = function()
			return {
				{
					"<leader>et",
					"<cmd>TransparentToggle<CR>",
					desc = "Toggle transparent background",
				},
			}
		end,
	},
}

return M
