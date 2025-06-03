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
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.INFO] = "",
						[vim.diagnostic.severity.HINT] = "",
					},
				} or {},
				virtual_text = {
					source = "if_many",
					spacing = 2,
					format = function(diagnostic)
						local diagnostic_message = {
							[vim.diagnostic.severity.ERROR] = diagnostic.message,
							[vim.diagnostic.severity.WARN] = diagnostic.message,
							[vim.diagnostic.severity.INFO] = diagnostic.message,
							[vim.diagnostic.severity.HINT] = diagnostic.message,
						}
						return diagnostic_message[diagnostic.severity]
					end,
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
		keys = function()
			return {
				{
					"<leader>ca",
					function()
						vim.lsp.buf.code_action()
					end,
					desc = "Code Action",
				},
				{
					"<leader>ca",
					function()
						vim.lsp.buf.range_code_action()
					end,
					mode = "v",
					desc = "Code Action (Range)",
				},
				{
					"<leader>cr",
					function()
						vim.lsp.buf.rename()
					end,
					desc = "Rename",
				},
				{
					"<leader>cd",
					function()
						require("telescope.builtin").lsp_definitions({
							layout_strategy = "vertical",
							layout_config = { width = 0.5 },
						})
					end,
					desc = "Peek Definition",
				},
				{
					"<leader>ci",
					function()
						require("telescope.builtin").lsp_implementations({
							layout_strategy = "vertical",
							layout_config = { width = 0.5 },
						})
					end,
					desc = "Peek Implementations",
				},
				{
					"<leader>cD",
					function()
						vim.lsp.buf.definition()
					end,
					desc = "Go to Definition",
				},
				{
					"<leader>ch",
					function()
						vim.lsp.buf.hover()
					end,
					desc = "Hover Documentation",
				},
				{
					"<leader>cn",
					function()
						vim.diagnostic.goto_next()
					end,
					desc = "Next Diagnostic",
				},
				{
					"<leader>cp",
					function()
						vim.diagnostic.goto_prev()
					end,
					desc = "Previous Diagnostic",
				},
			}
		end,
	},
}

return M
