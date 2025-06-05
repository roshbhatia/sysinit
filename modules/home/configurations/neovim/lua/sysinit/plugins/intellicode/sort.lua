local M = {}

M.plugins = {
	{
		"echasnovski/mini.operators",
		config = function()
			require("mini.operators").setup({
				evaluate = {
					prefix = "<leader>s=",
					func = nil,
				},
				exchange = {
					prefix = "<leader>sx",
					reindent_linewise = true,
				},
				multiply = {
					prefix = "<leader>sm",
					func = nil,
				},
				replace = {
					prefix = "<leader>sr",
					reindent_linewise = true,
				},
				sort = {
					prefix = "<leader>ss",
					func = function(lines)
						table.sort(lines)
						return lines
					end,
				},
			})
		end,
	},
}

return M

