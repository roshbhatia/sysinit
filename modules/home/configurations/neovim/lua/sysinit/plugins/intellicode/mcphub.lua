local M = {}

M.plugins = {
	{
		"ravitemer/mcphub.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("mcphub").setup({
				auto_approve = true,
				extensions = {
					avante = {
						make_slash_commands = true,
					},
				},
			})
		end,
	},
}

return M

