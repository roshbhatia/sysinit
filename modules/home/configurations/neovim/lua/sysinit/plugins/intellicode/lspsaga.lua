local M = {}

M.plugins = {
	{
		"nvimdev/lspsaga.nvim",
		event = { "LspAttach" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"neovim/nvim-lspconfig",
			"nvimtools/none-ls.nvim",
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
