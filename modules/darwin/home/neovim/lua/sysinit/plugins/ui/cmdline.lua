local M = {}

M.plugins = {
	{
		"VonHeikemen/fine-cmdline.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		keys = function()
			return {
				{
					"<leader><leader>",
					"<cmd>FineCmdline<cr>",
					desc = "Commandline",
				},
			}
		end,
	},
}

return M
