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
					"golangci_lint_ls",
					"gopls",
					"grammarly",
					"helm_ls",
					"jqls",
					"jsonls",
					"lua_ls",
					"marksman",
					"nixd",
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

