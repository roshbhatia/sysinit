local M = {}

M.plugins = {
	{
		"Al0den/notion.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
		},
		event = "VeryLazy",
		config = function()
			require("notion").setup()
		end,
		keys = function()
			return {
				{
					"<leader>fn",
					require("notion").openMenu,
					desc = "Notes",
				},
			}
		end,
	},
}

return M
