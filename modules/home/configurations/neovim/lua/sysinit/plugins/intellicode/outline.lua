local M = {}

M.plugins = {
	{
		"stevearc/aerial.nvim",
		cmd = { "AerialToggle" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("aerial").setup({
				highlight_on_hover = true,
				min_width = {
					20,
					0.1,
				},
				autojump = true,
				manage_folds = true,
				link_folds_to_tree = true,
				lsp = {
					diagnostics_trigger_update = true,
				},
				backends = {
					["_"] = {
						"treesitter",
						"lsp",
						"markdown",
						"asciidoc",
						"man",
					},
				},
			})
		end,
		keys = {
			{
				"<leader>eo",
				"<CMD>AerialToggle!<CR>",
				desc = "Toggle outline",
			},
		},
	},
}

return M

