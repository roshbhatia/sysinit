local M = {}

M.plugins = {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = {
			"b0o/SchemaStore.nvim",
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
					cmd = {
						"up",
						"xpls",
						"serve",
					},
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
			vim.lsp.inlay_hint.enable(true)

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client.supports_method("textDocument/codeLens") then
						vim.lsp.codelens.refresh()
						vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
							buffer = args.buf,
							callback = vim.lsp.codelens.refresh,
						})
					end
				end,
			})
		end,
		keys = function()
			return {
				{ "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },
				{ "<leader>cD", vim.lsp.buf.definition, desc = "Go to definition" },
				{ "<leader>cn", vim.diagnostic.get_next, desc = "Next diagnostic" },
				{ "<leader>cp", vim.diagnostic.get_prev, desc = "Previous diagnostic" },
				{ "<leader>cA", vim.lsp.codelens.run, desc = "Code lens actions" },
				{
					"<leader>ch",
					function()
						vim.lsp.buf.hover({ border = "rounded" })
					end,
					desc = "Hover documentation",
				},
				{
					"<leader>cj",
					function()
						vim.lsp.buf.signature_help({ border = "rounded" })
					end,
					desc = "Signature help",
				},
				{ "<leader>cs", vim.lsp.buf.document_symbol, desc = "Document symbols" },
				{ "<leader>cS", vim.lsp.buf.workspace_symbol, desc = "Workspace symbols" },
				{ "<leader>ci", "<cmd>LspInfo<cr>", desc = "LSP info" },
				{
					"<leader>cI",
					function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
					end,
					desc = "Toggle inlay hints",
				},
			}
		end,
	},
}

return M

