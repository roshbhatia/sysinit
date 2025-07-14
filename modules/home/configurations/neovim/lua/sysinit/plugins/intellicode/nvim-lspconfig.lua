local M = {}

M.plugins = {
	{
		"neovim/nvim-lspconfig",
		event = "BufReadPre",
		dependencies = {
			"aznhe21/actions-preview.nvim",
			"b0o/SchemaStore.nvim",
			"Fildo7525/pretty_hover",
			"folke/snacks.nvim",
			"saghen/blink.compat",
			"saghen/blink.cmp",
		},
		config = function()
			local schemastore = require("schemastore")
			local lspconfig = require("lspconfig")

			local builtin_servers = {
				gopls = {},
				tflint = {},
				dockerls = {},
				helm_ls = {},
				jqls = {},
				lua_ls = {},
				nil_ls = {},
				pyright = {},
				terraformls = {},
				jsonls = {
					settings = {
						json = {
							schemas = schemastore.json.schemas(),
							validate = { enable = true },
						},
					},
				},
				yamlls = {
					settings = {
						yaml = {
							schemaStore = { enable = false, url = "" },
							schemas = schemastore.yaml.schemas(),
						},
					},
				},
			}

			local custom_servers = {
				up = {
					cmd = { "up", "xpls", "serve", "--verbose" },
					filetypes = { "yaml" },
					root_dir = function()
						local fd = vim.fn.system("fd crossplane.yaml")
						return fd ~= "" and vim.fn.fnamemodify(fd, ":p:h") or vim.fn.getcwd()
					end,
				},
			}

			for server, config in pairs(builtin_servers) do
				config.capabilities = require("blink.cmp").get_lsp_capabilities()
				lspconfig[server].setup(config)
			end

			for server, config in pairs(custom_servers) do
				config.capabilities = require("blink.cmp").get_lsp_capabilities()
				vim.lsp.config(server, config)
				vim.lsp.enable(server)
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local bufnr = args.buf
					if vim.lsp.inlay_hint and client.supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
					end
					if vim.lsp.codelens and client.supports_method("textDocument/codeLens") then
						vim.lsp.codelens.refresh()
						local group = vim.api.nvim_create_augroup("LSPCodeLens" .. bufnr, { clear = true })
						vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
							group = group,
							buffer = bufnr,
							callback = vim.lsp.codelens.refresh,
						})
					end
				end,
			})

			vim.diagnostic.config({
				severity_sort = true,
				virtual_text = false,
				virtual_lines = { only_current_line = true },
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
		end,
		keys = function()
			return {
				{ "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },
				{ "<leader>cD", vim.lsp.buf.definition, desc = "Go to definition" },
				{ "<leader>cn", vim.diagnostic.goto_next, desc = "Next diagnostic" },
				{ "<leader>cp", vim.diagnostic.goto_prev, desc = "Previous diagnostic" },
			}
		end,
	},
}

return M

