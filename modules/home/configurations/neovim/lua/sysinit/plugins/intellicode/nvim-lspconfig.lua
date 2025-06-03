local M = {}

M.plugins = {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"folke/snacks.nvim",
		},
		config = function()
			vim.api.nvim_create_autocmd("LspProgress", {
				callback = function(ev)
					local status_message = vim.lsp.status()
					if string.find(status_message, "code_action") then
						return
					end

					local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
					vim.notify(status_message, "info", {
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
				virtual_text = false,
				update_in_insert = false,
				float = {
					source = true,
				},
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = " ",
						[vim.diagnostic.severity.INFO] = " ",
					},
				},
			})

			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			local function setup_lsp(server, opts)
				opts = opts or {}
				opts.capabilities = capabilities
				lspconfig[server].setup(opts)
			end

			local installed_lsps = mason_lspconfig.get_installed_servers()

			for _, lsp in ipairs(installed_lsps) do
				setup_lsp(lsp)
			end

			setup_lsp("gopls", {
				settings = {
					gopls = {
						analyses = {
							unusedparams = true,
							unusedvariable = true,
						},
						staticcheck = true,
						gofumpt = true,
					},
				},
			})

			setup_lsp("jsonls", {
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						validate = { enable = true },
					},
				},
			})

			setup_lsp("lua_ls", {
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
						},
						diagnostics = {
							globals = {
								"vim",
								"require",
							},
						},
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
						},
						telemetry = {
							enable = false,
						},
					},
				},
			})

			setup_lsp("nixd", {
				settings = {
					nixd = {
						nixpkgs = {
							expr = "import <nixpkgs> { }",
						},
						formatting = {
							command = { "nixfmt" },
						},
						options = {
							home_manager = {
								expr = '(builtins.getFlake (".")).darwinConfigurations."'
									.. vim.fn.hostname()
									.. '".options',
							},
						},
					},
				},
			})

			setup_lsp("yamlls", {
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
}

return M

