local M = {}

M.plugins = {
	{
		"williamboman/mason.nvim",
		lazy = false,
		opts = {
			install_root_dir = vim.fn.stdpath("data") .. "/mason",
			ui = {
				border = "single",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		lazy = false,
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
					"html",
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
