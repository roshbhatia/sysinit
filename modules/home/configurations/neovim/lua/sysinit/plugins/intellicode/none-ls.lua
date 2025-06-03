local M = {}

M.plugins = {
	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.code_actions.gomodifytags,
					null_ls.builtins.code_actions.impl,
					null_ls.builtins.code_actions.refactoring,
					null_ls.builtins.code_actions.statix,
					null_ls.builtins.code_actions.textlint,
					null_ls.builtins.completion.spell,
					null_ls.builtins.diagnostics.markdownlint,
					null_ls.builtins.diagnostics.proselint,
					null_ls.builtins.diagnostics.yamllint,
					null_ls.builtins.formatting.goimports,
					null_ls.builtins.hover.dictionary,
					null_ls.builtins.hover.printenv,
				},
			})
		end,
	},
}

return M
