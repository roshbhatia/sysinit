local M = {}

M.plugins = {
	{
		"fnune/recall.nvim",
		version = "*",
		config = function()
			local recall = require("recall")
			recall.setup({})
		end,
		keys = function()
			return {
				{
					"<leader>mm",
					function()
						require("recall").toggle()
					end,
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Marks: Toggle",
				},
				{
					"<leader>mn",
					function()
						require("recall").goto_next()
					end,
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Marks: Next",
				},
				{
					"<leader>mp",
					function()
						require("recall").goto_prev()
					end,
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Marks: Previous",
				},
				{
					"<leader>mc",
					function()
						require("recall").clear()
					end,
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Marks: Clear",
				},
				{
					"<leader>ml",
					":Telescope recall<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Picker: Marks",
				},
			}
		end,
	},
}

return M
