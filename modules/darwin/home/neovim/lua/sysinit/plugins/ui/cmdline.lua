local M = {}

M.plugins = {
	{
		"VonHeikemen/fine-cmdline.nvim",
		dependencies = { { "MunifTanjim/nui.nvim" } },
		lazy = false,
		config = function()
			require("fine-cmdline").setup({
				cmdline = {
					enable_keymaps = true,
					smart_history = true,
					prompt = ": ",
				},
				popup = {
					position = {
						row = "10%",
						col = "50%",
					},
					size = {
						width = "60%",
					},
					border = {
						style = "single",
					},
					win_options = {
						winblend = 50,
						winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
					},
				},
			})
		end,
	},
}

return M
