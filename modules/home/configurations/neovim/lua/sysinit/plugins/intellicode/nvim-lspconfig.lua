local M = {}

M.plugins = {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"b0o/SchemaStore.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"folke/snacks.nvim",
			{
				"aznhe21/actions-preview.nvim",
				config = function()
					require("actions-preview").setup({
						telescope = vim.tbl_extend(
							"force",
							-- telescope theme: https://github.com/nvim-telescope/telescope.nvim#themes
							require("telescope.themes").get_ivy(),
							{
								make_value = nil,
								make_make_display = nil,
							}
						),
					})
				end,
			},
			{
				"Fildo7525/pretty_hover",
				event = "LspAttach",
				opts = {},
			},
		},
		config = function()
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local lspconfig = require("lspconfig")
			local configs = require("lspconfig/configs")
			local mason_lspconfig = require("mason-lspconfig")
			local mason_tool_installer = require("mason-tool-installer")

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function()
					vim.diagnostic.config({
						severity_sort = false,
						virtual_text = false,
						virtual_lines = {
							only_current_line = true,
						},
						update_in_insert = true,
						float = {
							border = "rounded",
							source = "if_many",
						},
						underline = {
							severity = vim.diagnostic.severity.ERROR,
						},
						signs = {
							text = {
								[vim.diagnostic.severity.ERROR] = "",
								[vim.diagnostic.severity.HINT] = "",
								[vim.diagnostic.severity.INFO] = "",
								[vim.diagnostic.severity.WARN] = "",
							},
							numhl = {
								[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
								[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
								[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
								[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
							},
						},
					})
				end,
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, cmp_nvim_lsp.default_capabilities())

			if not configs.golangcilsp then
				configs.golangcilsp = {
					default_config = {
						cmd = { "golangci-lint-langserver" },
						root_dir = lspconfig.util.root_pattern(".git", "go.mod"),
						init_options = {
							command = {
								"golangci-lint",
								"run",
								"--output.json.path",
								"stdout",
								"--show-stats=false",
								"--issues-exit-code=1",
							},
						},
					},
				}
			end

			local servers = {
				bashls = {},
				dagger = {},
				docker_compose_language_service = {},
				dockerls = {},
				golangci_lint_ls = {
					filetypes = {
						"go",
						"gomod",
					},
				},
				gopls = {
					settings = {
						gopls = {
							analyses = {
								unusedvariable = true,
								unusedwrite = true,
								useany = true,
								fieldalignment = true,
							},
							gofumpt = true,
							hoverKind = "SynopsisDocumentation",
							codelenses = {
								gc_details = false,
								generate = true,
								regenerate_cgo = true,
								run_govulncheck = true,
								test = true,
								tidy = true,
								upgrade_dependency = true,
								vendor = true,
							},
							hints = {
								parameterNames = true,
							},
							completeUnimported = true,
							semanticTokens = true,
						},
					},
				},
				helm_ls = {},
				jqls = {},
				jsonls = {
					settings = {
						json = {
							schemas = require("schemastore").json.schemas(),
							validate = {
								enable = true,
							},
						},
					},
				},
				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				},
				nil_ls = {},
				pyright = {},
				terraformls = {},
				tflint = {},
				ts_ls = {},
				vimls = {},
				yamlls = {
					settings = {
						yaml = {
							schemaStore = {
								-- You must disable built-in schemaStore support if you want to use
								-- this plugin and its advanced options like `ignore`.
								enable = false,
								-- Avoid TypeError: Cannot read properties of undefined (reading 'length')
								url = "",
							},
							schemas = require("schemastore").yaml.schemas(),
						},
					},
				},
			}

			local tools = {
				"impl",
				"golines",
			}

			mason_tool_installer.setup({
				ensure_installed = vim.list_extend(tools, vim.tbl_keys(servers)),
			})

			mason_lspconfig.setup({
				ensure_installed = vim.tbl_keys(servers),
				automatic_enable = true,
				handlers = function(server_name)
					lspconfig[server_name].setup({
						capabilities = capabilities,
						settings = servers[server_name],
						filetypes = (servers[server_name] or {}).filetypes,
					})
				end,
			})
		end,
		keys = function()
			return {
				{
					"<leader>ca",
					function()
						require("actions-preview").code_actions()
					end,
					desc = "Code action",
				},
				{
					"<leader>ca",
					function()
						require("actions-preview").code_actions()
					end,
					mode = "v",
					desc = "Code action",
				},
				{
					"<leader>cr",
					function()
						vim.lsp.buf.rename()
					end,
					desc = "Rename",
				},
				{
					"<leader>cD",
					function()
						vim.lsp.buf.definition()
					end,
					desc = "Go to definition",
				},
				{
					"<leader>ch",
					function()
						require("pretty_hover").hover()
					end,
					desc = "Hover documentation",
				},

				{
					"K",
					function()
						require("pretty_hover").hover()
					end,
					desc = "Hover documentation",
				},
				{
					"<leader>cn",
					function()
						vim.diagnostic.goto_next()
					end,
					desc = "Next diagnostic",
				},
				{
					"<leader>cp",
					function()
						vim.diagnostic.goto_prev()
					end,
					desc = "Previous diagnostic",
				},
			}
		end,
	},
}

return M

