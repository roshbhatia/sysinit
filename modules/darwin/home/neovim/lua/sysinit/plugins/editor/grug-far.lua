local M = {}

M.plugins = {
	{
		"MagicDuck/grug-far.nvim",
		commit = "f24022147ca4a0fe1d424a520a9437accbeba193",
		config = function()
			require("grug-far").setup()
		end,
		keys = function()
			return {
				{
					"<leader>ig",
					function()
						require("grug-far").open()
					end,
					desc = "Search: Global",
				},
			}
		end,
	},
}

return M
