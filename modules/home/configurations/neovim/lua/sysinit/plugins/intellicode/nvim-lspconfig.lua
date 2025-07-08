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

			local lsp_servers = {
				docker_compose_language_service = {},
				dockerls = {},
				helm_ls = {},
				jqls = {},
				jsonls = {
					settings = {
						json = {
							schemas = schemastore.json.schemas(),
							validate = { enable = true },
						},
					},
				},
				lua_ls = {},
				nil_ls = {},
				pyright = {},
				terraformls = {},
				tflint = {},
				ts_ls = {},
				yamlls = {
					settings = {
						yaml = {
							schemaStore = { enable = false, url = "" },
							schemas = schemastore.yaml.schemas(),
						},
					},
				},
				up = {
					cmd = { "up", "xpls", "serve", "--verbose" },
					filetypes = { "yaml" },
					root_dir = function()
						local fd = vim.fn.system("fd crossplane.yaml")
						return fd ~= "" and vim.fn.fnamemodify(fd, ":p:h") or vim.fn.getcwd()
					end,
				},
			}

			for server_name, server_config in pairs(lsp_servers) do
				server_config.capabilities = require("blink.cmp").get_lsp_capabilities(server_config.capabilities)
				lspconfig[server_name].setup(server_config)
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
		config = function(lp, opts)
			require("go").setup(opts)
			local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*.go",
				callback = function()
					require("go.format").goimports()
				end,
				group = format_sync_grp,
			})
		end,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()',
	},
}

return M
