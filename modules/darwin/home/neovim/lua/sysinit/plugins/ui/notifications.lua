local M = {}

M.plugins = {
	{
		"j-hui/fidget.nvim",
		opts = {
			notification = {
				override_vim_notify = true,
				window = {
					border = "rounded",
					winblend = 25,
					align = "top",
				},
			},
		},
		keys = function()
			return {
				{
					"<leader>ns",
					function()
						require("fidget.notification").show_history()
					end,
					desc = "Notifications: show",
				},
				{
					"<leader>nc",
					function()
						require("fidget.notification").clear()
					end,
					desc = "Notifications: clear",
				},
			}
		end,
	},
}

return M
