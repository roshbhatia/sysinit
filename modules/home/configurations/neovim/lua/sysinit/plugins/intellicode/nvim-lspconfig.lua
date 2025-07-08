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
		},
		config = function()
			local schemastore = require("schemastore")
			local lspconfig = require("lspconfig")
			local capabilities = vim.tbl_deep_extend(
				"force",
				vim.lsp.protocol.make_client_capabilities(),
				require("blink.cmp").get_lsp_capabilities() or {}
			)

			local servers = {
				tflint = lspconfig.configs.tflint.default_config,
				dockerls = lspconfig.configs.dockerls.default_config,
				helm_ls = lspconfig.configs.helm_ls.default_config,
				jqls = lspconfig.configs.jqls.default_config,
				lua_ls = lspconfig.configs.lua_ls.default_config,
				nil_ls = lspconfig.configs.nil_ls.default_config,
				pyright = lspconfig.configs.pyright.default_config,
				terraformls = lspconfig.configs.terraformls.default_config,
				ts_ls = lspconfig.configs.ts_ls.default_config,
				jsonls = vim.tbl_deep_extend("force", lspconfig.configs.jsonls.default_config, {
					settings = {
						json = {
							schemas = schemastore.json.schemas(),
							validate = { enable = true },
						},
					},
				}),
				yamlls = vim.tbl_deep_extend("force", lspconfig.configs.yamlls.default_config, {
					settings = {
						yaml = {
							schemaStore = { enable = false, url = "" },
							schemas = schemastore.yaml.schemas(),
						},
					},
				}),
				up = {
					cmd = { "up", "xpls", "serve", "--verbose" },
					filetypes = { "yaml" },
					root_dir = function()
						local fd = vim.fn.system("fd crossplane.yaml")
						return fd ~= "" and vim.fn.fnamemodify(fd, ":p:h") or vim.fn.getcwd()
					end,
				},
			}

			for name, config in pairs(servers) do
				config.capabilities = capabilities
				vim.lsp.config(name, config)
				vim.lsp.enable(name)
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
	{
		"ray-x/go.nvim",
		dependencies = {
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			lsp_keymaps = false,
			icons = false,
			lsp_document_formatting = false,
			dap_debug_keymap = false,
			trouble = true,
		},
		config = function(_, opts)
			require("go").setup(opts)
		end,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
	},
}

return M
