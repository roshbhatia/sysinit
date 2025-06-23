local M = {}

M.plugins = {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"aznhe21/actions-preview.nvim",
			"b0o/SchemaStore.nvim",
			"Fildo7525/pretty_hover",
			"folke/snacks.nvim",
			"saghen/blink.compat",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			local blink_cmp = require("blink.cmp")
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local mason_tool_installer = require("mason-tool-installer")

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					vim.diagnostic.config({
						severity_sort = true,
						virtual_text = false,
						virtual_lines = {
							only_current_line = false,
						},
						update_in_insert = false,
						float = {
							border = "rounded",
							source = "if_many",
						},
						underline = {
							severity = vim.diagnostic.severity.ERROR,
						},
						signs = {
							text = {
								[vim.diagnostic.severity.ERROR] = "",
								[vim.diagnostic.severity.HINT] = "",
								[vim.diagnostic.severity.INFO] = "",
								[vim.diagnostic.severity.WARN] = "",
							},
							numhl = {
								[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
								[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
								[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
								[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
							},
						},
					})

					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client.server_capabilities.inlayHintProvider then
						vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
					end
				end,
			})

			local servers = {
				bashls = {
					source = "mason",
				},
				crossplane = {
					source = "system",
					cmd = {
						"up",
						"xpls",
						"serve",
						"--verbose",
					},
					filetypes = {
						"yaml",
					},
				},
				dagger = {
					source = "mason",
				},
				docker_compose_language_service = {
					source = "mason",
				},
				dockerls = {
					source = "mason",
				},
				gopls = {
					source = "mason",
					filetypes = {
						"go",
						"gomod",
						"gotpml",
						"gowork",
					},
					settings = {
						go = {
							gofumpt = true,
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
								assignVariableTypes = true,
								compositeLiteralFields = true,
								compositeLiteralTypes = true,
								constantValues = true,
								functionTypeParameters = true,
								parameterNames = true,
								rangeVariableTypes = true,
							},
							analyses = {
								fieldalignment = true,
								nilness = true,
								unusedparams = true,
								unusedwrite = true,
								useany = true,
							},
							usePlaceholders = true,
							completeUnimported = true,
							staticcheck = true,
							directoryFilters = {
								"-.git",
								"-.vscode",
								"-.idea",
								"-.vscode-test",
								"-node_modules",
							},
							semanticTokens = true,
						},
					},
				},
				helm_ls = {
					source = "mason",
					settings = {
						["helm-ls"] = {
							yamlls = {
								path = "yaml-language-server",
							},
						},
					},
				},
				jqls = {
					source = "mason",
				},
				jsonls = {
					source = "mason",
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
					source = "mason",
				},
				nil_ls = {
					source = "mason",
					settings = {
						["nil"] = {
							testSetting = 42,
						},
					},
				},
				pyright = {
					source = "mason",
				},
				terraformls = {
					source = "mason",
				},
				tflint = {
					source = "mason",
				},
				ts_ls = {
					source = "mason",
				},
				yamlls = {
					source = "mason",
					settings = {
						yaml = {
							schemaStore = {
								enable = false,
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
			local mason_servers = vim.deepcopy(servers)
			mason_servers.crossplane = nil

			mason_tool_installer.setup({
				ensure_installed = vim.list_extend(tools, vim.tbl_keys(mason_servers)),
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, blink_cmp.get_lsp_capabilities({}, false))

			mason_lspconfig.setup({
				ensure_installed = vim.tbl_keys(mason_servers),
				automatic_enable = true,
				handlers = function(server_name)
					lspconfig[server_name].setup({
						capabilities = (servers[server_name] or {}).capabilities + capabilities,
						filetypes = (servers[server_name] or {}).filetypes,
						on_init = function(client)
							if client.supports_method("textDocument/semanticTokens") then
								client.server_capabilities.semanticTokensProvider = nil
							end
						end,
						settings = (servers[server_name] or {}).settings,
					})
				end,
			})

			lspconfig.crossplane.setup({
				cmd = servers.crossplane.cmd,
				capabilities = capabilities,
				filetypes = servers.crossplane.filetypes,
				on_init = function(client)
					if client.supports_method("textDocument/semanticTokens") then
						client.server_capabilities.semanticTokensProvider = nil
					end
				end,
				settings = {
					xpls = {
						up = {
							path = "up",
						},
					},
				},
			})
		end,
		keys = function()
			return {
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
