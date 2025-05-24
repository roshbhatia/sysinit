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
					"<leader>fs",
					function()
						require("grug-far").open()
					end,
					desc = "Find: Global search",
				},
				{
					"<leader>fr",
					function()
						require("grug-far").open()
					end,
					desc = "Find: Global search and replace",
				},
			}
		end,
	},
}

return M
