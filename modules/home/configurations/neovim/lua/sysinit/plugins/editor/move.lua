local M = {}

M.plugins = {
	{
		"echasnovski/mini.move",
		version = "*",
		config = function()
			require("mini.move").setup({
				mappings = {
					-- Move visual selection in Visual mode. Use LocalLeader + hjkl.
					left = "<LocalLeader>h",
					right = "<LocalLeader>l",
					down = "<LocalLeader>j",
					up = "<LocalLeader>k",

					-- Move current line in Normal mode
					line_left = "<LocalLeader>h",
					line_right = "<LocalLeader>l",
					line_down = "<LocalLeader>j",
					line_up = "<LocalLeader>k",
				},
				options = {
					reindent_linewise = true,
				},
			})
		end,
	},
}

return M

