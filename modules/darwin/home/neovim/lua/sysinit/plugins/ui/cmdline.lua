local M = {}

M.plugins = {
	{
		"VonHeikemen/fine-cmdline.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		config = function()
			require("fine-cmdline").setup({
				win_options = {
					winblend = 30,
					border = "single",
				},
			})
		end,
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
