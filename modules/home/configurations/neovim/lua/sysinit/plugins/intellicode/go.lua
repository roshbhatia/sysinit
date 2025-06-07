local M = {}

M.plugins = {
	{
		"ray-x/go.nvim",
		dependencies = {
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			lsp_keymaps = false,
			trouble = true,
			luasnip = true,
		},
		config = function(lp, opts)
			require("go").setup(opts)
		end,
		event = { "BufReadPost" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()',
	},
}

return M
