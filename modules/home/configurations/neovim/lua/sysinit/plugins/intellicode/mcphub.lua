local M

M.plugins = {
	{
		"ravitemer/mcphub.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		build = "bundled_build.lua",
		config = function()
			require("mcphub").setup({
				auto_approve = true,
				extensions = {
					avante = {
						make_slash_commands = true,
					},
				},
				use_bundled_binary = true,
			})
		end,
	},
}

return M
