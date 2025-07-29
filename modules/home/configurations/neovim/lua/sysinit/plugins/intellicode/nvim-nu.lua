local M = {}

M.plugins = {
	{
		"LhKipp/nvim-nu",
		build = ":TSInstall nu",
		opts = {},
		ft = "nu",
	},
}

return M

