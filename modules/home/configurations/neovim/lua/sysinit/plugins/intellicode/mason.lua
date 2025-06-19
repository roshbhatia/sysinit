local M = {}

M.plugins = {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				ensure_installed = {
					"actionlint",
					"checkmake",
					"deadnix",
					"eslint",
					"golangci-lint",
					"gopls",
					"jsonlint",
					"lua-language-server",
					"markdownlint-cli",
					"shellcheck",
					"staticcheck",
					"terraform-cli",
					"tflint",
					"tfsec",
					"typescript-language-server",
					"yamllint",
				},
			})
		end,
	},
}

return M
