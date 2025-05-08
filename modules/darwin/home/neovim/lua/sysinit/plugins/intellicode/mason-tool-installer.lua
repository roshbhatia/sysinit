local M = {}

M.plugins = {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"bashls",
					"dagger",
					"docker_compose_language_service",
					"dockerls",
					"golangci_lint_ls",
					"gopls",
					"helm_ls",
					"jqls",
					"jsonls",
					"lua_ls",
					"marksman",
					"nil_ls",
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
