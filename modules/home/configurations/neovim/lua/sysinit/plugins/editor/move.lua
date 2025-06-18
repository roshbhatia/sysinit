local M = {}

M.plugins = {
	{
		"echasnovski/mini.move",
		version = "*",
		config = function()
			require("mini.move").setup({
				mappings = {
					-- Move visual selection in Visual mode.
					left = "<leader>h",
					right = "<leader>l",
					down = "<leader>j",
					up = "<leader>k",

					-- Move current line in Normal mode
					line_left = "<leader>h",
					line_right = "<leader>l",
					line_down = "<leader>j",
					line_up = "<leader>k",
				},
				options = {
					reindent_linewise = true,
				},
			})
		end,
	},
}

return M

