local M = {}

M.plugins = {
	{
		"MagicDuck/grug-far.nvim",
		config = function()
			require("grug-far").setup()
		end,
		keys = function()
			return {
				{
					"<leader>ig",
					function()
						require("grug-far").toggle_instance({ instanceName = "far", staticTitle = "Global Search" })
					end,
					desc = "Search and replace within current project",
				},
			}
		end,
	},
}

return M

