local M = {}

M.plugins = {
	{
		"VonHeikemen/fine-cmdline.nvim",
		dependencies = { { "MunifTanjim/nui.nvim" } },
		lazy = false,
		keys = function()
			return {
				{
					"<leader><leader>",
					"<cmd>FineCmdline<cr>",
					desc = "Commandline",
				},
			}
		end,
		config = function()
			require("fine-cmdline").setup({
				cmdheight = 0,
				win_options = {
					winblend = 30,
					border = "single",
				},
			})
		end,
	},
}

return M
