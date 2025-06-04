local M = {}

M.plugins = {
	{
		"nvimdev/lspsaga.nvim",
		event = { "LspAttach" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("lspsaga").setup({
				symbol_in_winbar = {
					enable = false,
				},
				lightbulb = {
					virtual_text = false,
				},
				ui = {
					code_action = "󱥸",
					actionfix = "󰥲",
				},
			})
		end,
	},
}

return M
