local M = {}

M.plugins = {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"bashls",
					"dagger",
					"docker_compose_language_service",
					"dockerls",
					"golangci_lint_ls",
					"gopls",
					"golines",
					"helm_ls",
					"impl",
					"json-to-struct",
					"jqls",
					"jsonls",
					"lua-language-server",
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
