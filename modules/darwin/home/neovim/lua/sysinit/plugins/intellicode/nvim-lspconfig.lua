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
			require("lspsaga").setup({
				lightbulb = {
					sign = false,
				},
				code_action = " 󰘧 ",
				actionfix = " 󰁨 ",
				imp_sign = "  ",
				border_style = "round",
			})
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"neovim/nvim-lspconfig",
		},
		keys = function()
			return {
				{ "<leader>ca", "<cmd>Lspsaga code_action<CR>", desc = "Code Action" },
				{ "<leader>ca", "<cmd><C-U>Lspsaga code_action<CR>", mode = "v", desc = "Code Action (Range)" },
				{ "<leader>cr", "<cmd>Lspsaga rename<CR>", desc = "Rename" },
				{ "<leader>cd", "<cmd>Lspsaga peek_definition<CR>", desc = "Peek Definition" },
				{ "<leader>cD", "<cmd>Lspsaga goto_definition<CR>", desc = "Go to Definition" },
				{ "<leader>ct", "<cmd>Lspsaga peek_type_definition<CR>", desc = "Peek Type Definition" },
				{ "<leader>ch", "<cmd>Lspsaga hover_doc<CR>", desc = "Hover Documentation" },
				{ "<leader>cf", "<cmd>Lspsaga finder<CR>", desc = "Find References" },
				{ "<leader>co", "<cmd>Lspsaga outline<CR>", desc = "Show Outline" },
				{ "<leader>ci", "<cmd>Lspsaga incoming_calls<CR>", desc = "Incoming Calls" },
				{ "<leader>cu", "<cmd>Lspsaga outgoing_calls<CR>", desc = "Outgoing Calls" },
				{ "<leader>cl", "<cmd>Lspsaga diagnostic_jump_next<CR>", desc = "Next Diagnostic" },
				{ "<leader>cL", "<cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "Previous Diagnostic" },
			}
		end,
	},
}

return M
