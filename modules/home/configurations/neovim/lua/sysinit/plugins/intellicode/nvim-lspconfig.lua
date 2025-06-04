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
					highlight_command = {
						require("actions-preview.highlight").delta(),
					},
					telescope = vim.tbl_extend("force", require("telescope.themes").get_ivy({ winblend = 10 }), {
						make_value = nil,
						make_make_display = nil,
					})
					}),
				end
			},
		},
		config = function()
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local mason_tool_installer = require("mason-tool-installer")

			vim.api.nvim_create_autocmd("LspProgress", {
				callback = function(ev)
					local status_message = vim.lsp.status()
					-- Avoid showing progress for code action availability
					if string.find(status_message, "code_action") then
						return
					end

					local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
					vim.notify(status_message, vim.log.levels.INFO, {
						id = "lsp_progress",
						title = "LSP Progress",
						opts = function(notif)
							notif.icon = ev.data.params.value.kind == "end" and " "
								or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
						end,
					})
				end,
			})

			vim.diagnostic.config({
				severity_sort = true,
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

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, cmp_nvim_lsp.default_capabilities())

			local servers = {
				bashls = {},
				dagger = {},
				docker_compose_language_service = {},
				dockerls = {},
				golangci_lint_ls = {},
				gopls = {
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
						assignVariableTypes = false,
						compositeLiteralFields = false,
						compositeLiteralTypes = false,
						constantValues = false,
						functionTypeParameters = false,
						parameterNames = false,
						rangeVariableTypes = false,
					},
					analyses = {
						nilness = true,
						unusedparams = true,
						unusedwrite = true,
						useany = true,
						unreachable = true,
						modernize = true,
						stylecheck = true,
						appends = true,
						asmdecl = true,
						assign = true,
						atomic = true,
						bools = true,
						buildtag = true,
						cgocall = true,
						composite = true,
						contextcheck = true,
						deba = true,
						atomicalign = true,
						composites = true,
						copylocks = true,
						deepequalerrors = true,
						defers = true,
						deprecated = true,
						directive = true,
						embed = true,
						errorsas = true,
						fillreturns = true,
						framepointer = true,
						gofix = true,
						hostport = true,
						infertypeargs = true,
						lostcancel = true,
						httpresponse = true,
						ifaceassert = true,
						loopclosure = true,
						nilfunc = true,
						nonewvars = true,
						noresultvalues = true,
						printf = true,
						shadow = true,
						shift = true,
						sigchanyzer = true,
						simplifycompositelit = true,
						simplifyrange = true,
						simplifyslice = true,
						slog = true,
						sortslice = true,
						stdmethods = true,
						stdversion = true,
						stringintconv = true,
						structtag = true,
						testinggoroutine = true,
						tests = true,
						timeformat = true,
						unmarshal = true,
						unsafeptr = true,
						unusedfunc = true,
						unusedresult = true,
						waitgroup = true,
						yield = true,
						unusedvariable = true,
					},
				},
				helm_ls = {},
				jqls = {},
				jsonls = {
					settings = {
						json = {
							schemas = require("schemastore").json.schemas(),
							validate = { enable = true },
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
						vim.lsp.buf.hover({
							border = "rounded",
						})
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
