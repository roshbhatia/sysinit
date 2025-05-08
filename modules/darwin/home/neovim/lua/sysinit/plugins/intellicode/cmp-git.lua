local M = {}

M.plugins = {
	{
		"petertriho/cmp-git",
		dependencies = { "hrsh7th/nvim-cmp" },
		opts = {},
		init = function()
			table.insert(require("cmp").get_config().sources, { name = "git" })
		end,
	},
}

return M
