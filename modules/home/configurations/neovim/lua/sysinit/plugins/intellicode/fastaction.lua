local M = {}

M.plugins = {
	{
		"Chaitanyabsprip/fastaction.nvim",
		opts = {},
		event = "LSPAttach",
		keys = function()
			return {
				{
					"<leader>ca",
					function()
						require("fastaction").code_action()
					end,
					desc = "Code action",
				},
				{
					"<leader>ca",
					function()
						require("fastaction").code_actions()
					end,
					mode = "v",
					desc = "Code action",
				},
			}
		end,
	},
}

return M
