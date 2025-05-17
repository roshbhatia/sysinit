local M = {}

M.plugins = {
	{
		"Bekaboo/dropbar.nvim",
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		config = function()
			local dropbar_api = require("dropbar.api")
			vim.keymap.set("n", "<Leader>fx", dropbar_api.pick, { desc = "Pick: Symbols in winbar" })
		end,
	},
}

return M
