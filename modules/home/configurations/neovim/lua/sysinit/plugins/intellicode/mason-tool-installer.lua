local M = {}

M.plugins = {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"bashls",
					"dagger",
					"docker_compose_language_service",
					"dockerls",
					"fillswitch",
					"golangci_lint_ls",
					"gopls",
					"gofumpt",
					"golines",
					"govulncheck",
					"helm_ls",
					"impl",
					"json-to-struct",
					"jqls",
					"jsonls",
					"pyright",
					"terraformls",
					"tflint",
					"ts_ls",
					"vimls",
					"yamlls",
				},
			})
		end,
	},
}

return M
