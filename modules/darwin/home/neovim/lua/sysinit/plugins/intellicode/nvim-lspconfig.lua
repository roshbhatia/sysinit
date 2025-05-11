local M = {}

M.plugins = {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			local lspconfig = require("lspconfig")

			lspconfig.bashls.setup({})
			lspconfig.dagger.setup({})
			lspconfig.docker_compose_language_service.setup({})
			lspconfig.dockerls.setup({})
			lspconfig.golangci_lint_ls.setup({})
			lspconfig.gopls.setup({})
			lspconfig.helm_ls.setup({})
			lspconfig.jqls.setup({})
			lspconfig.jsonls.setup({
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						validate = { enable = true },
					},
				},
			})
			lspconfig.lua_ls.setup({})
			lspconfig.marksman.setup({})
			lspconfig.nixd.setup({})
			lspconfig.pyright.setup({})
			lspconfig.terraformls.setup({})
			lspconfig.tflint.setup({})
			lspconfig.ts_ls.setup({})
			lspconfig.vimls.setup({})
			lspconfig.yamlls.setup({
				settings = {
					yaml = {
						schemaStore = {
							enable = false,
							url = "",
						},
						schemas = require("schemastore").yaml.schemas(),
					},
				},
			})
		end,
	},
	{
		"nvimdev/lspsaga.nvim",
		event = { "LspAttach" },
		config = function()
			require("lspsaga").setup({})
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"neovim/nvim-lspconfig",
		},
	},
}

return M

