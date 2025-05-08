local M = {}

M.plugins = {
	{
		"sQVe/sort.nvim",
		lazy = true,
		config = function()
			vim.api.nvim_create_user_command("Sort", function()
				require("sort").sort()
			end, {})
		end,
	},
}

return M
