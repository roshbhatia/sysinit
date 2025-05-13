local M = {}

M.plugins = {
	{
		"sQVe/sort.nvim",
		cmd = { "Sort" },
		config = function()
			vim.api.nvim_create_user_command("Sort", function()
				require("sort").sort()
			end, {})
		end,
		keys = function()
			vim.keymap.set("v", "<leader>ss", function()
				require("sort").sort()
			end, { desc = "Sort: Sort selection" })
		end,
	},
}

return M
