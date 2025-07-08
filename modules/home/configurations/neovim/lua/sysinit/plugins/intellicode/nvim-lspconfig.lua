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
			local dependencies = {
				blink_cmp = require("blink.cmp"),
				lspconfig = require("lspconfig"),
				mason_lspconfig = require("mason-lspconfig"),
				mason_tool_installer = require("mason-tool-installer"),
				configs = require("lspconfig.configs"),
				capabilities = vim.tbl_deep_extend(
					"force",
					vim.lsp.protocol.make_client_capabilities(),
					require("blink.cmp").get_lsp_capabilities({}, false)
				),
			}

			vim.diagnostic.config({
				severity_sort = true,
				virtual_text = false,
				virtual_lines = {
					only_current_line = true,
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

			local lsp_servers = {
				bashls = {
					source = "mason",
					external = false,
				},
				dagger = {
					source = "mason",
					external = false,
				},
				docker_compose_language_service = {
					source = "mason",
					external = false,
				},
				dockerls = {
					source = "mason",
					external = false,
				},
				gopls = {
					source = "mason",
					external = false,
					flags = {
						debounce_text_changes = 200,
					},
					filetypes = {
						"go",
						"gomod",
						"gowork",
						"gohtml",
						"gotmpl",
						"go.html",
						"go.tmpl",
					},
					settings = {
						gopls = {
							usePlaceholders = true,
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
							experimentalPostfixCompletions = true,
							completeUnimported = true,
							staticcheck = true,
							directoryFilters = {
								"-.git",
								"-node_modules",
							},
							semanticTokens = true,
							hints = {
								assignVariableTypes = true,
								compositeLiteralFields = true,
								compositeLiteralTypes = true,
								constantValues = true,
								functionTypeParameters = true,
								parameterNames = true,
								rangeVariableTypes = true,
							},
						},
					},
				},
				helm_ls = {
					source = "mason",
					external = false,
				},
				jqls = {
					source = "mason",
					external = false,
				},
				jsonls = {
					source = "mason",
					external = false,
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
					external = false,
				},
				nil_ls = {
					source = "mason",
					external = false,
					settings = {
						["nil"] = {
							testSetting = 42,
						},
					},
				},
				pyright = {
					source = "mason",
					external = false,
				},
				terraformls = {
					source = "mason",
					external = false,
				},
				tflint = {
					source = "mason",
					external = false,
				},
				ts_ls = {
					source = "mason",
					external = false,
				},
				yamlls = {
					source = "mason",
					external = false,
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
				up = {
					source = "system",
					external = true,
					cmd = {
						"up",
						"xpls",
						"serve",
						"--verbose",
					},
					filetypes = {
						"yaml",
					},
					root_dir = function()
						local fd = vim.fn.system("fd crossplane.yaml")
						if fd ~= "" then
							return vim.fn.fnamemodify(fd, ":p:h")
						end
						return nil
					end,
				},
			}

			local tools = {
				"impl",
			}

			dependencies.mason_tool_installer.setup({
				ensure_installed = tools,
			})

			dependencies.mason_lspconfig.setup({
				ensure_installed = vim.tbl_filter(function(server_name)
					return lsp_servers[server_name].source == "mason" and not lsp_servers[server_name].external
				end, vim.tbl_keys(lsp_servers)),
				automatic_enable = true,
				handlers = function(server_name)
					if lsp_servers[server_name] and not lsp_servers[server_name].external then
						dependencies.lspconfig[server_name].setup(
							vim.tbl_deep_extend("force", lsp_servers[server_name], {
								capabilities = dependencies.capabilities,
							})
						)
					end
				end,
			})

			for server_name, server_config in pairs(lsp_servers) do
				if server_config.external then
					dependencies.configs[server_name] = {
						default_config = server_config,
					}
					dependencies.lspconfig[server_name].setup(server_config)
				end
			end
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

