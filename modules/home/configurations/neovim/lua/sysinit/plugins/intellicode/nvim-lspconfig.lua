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
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.HINT] = "",
						[vim.diagnostic.severity.INFO] = "",
					},
				},
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

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, cmp_nvim_lsp.default_capabilities())

			local servers = {
				bashls = {},
				dagger = {},
				docker_compose_language_service = {},
				dockerls = {},
				golangci_lint_ls = {},
				gopls = {},
				helm_ls = {},
				jqls = {},
				jsonls = {},
				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				},
				pyright = {},
				terraformls = {},
				tflint = {},
				ts_ls = {},
				vimls = {},
				yamlls = {},
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
						vim.lsp.buf.code_action()
					end,
					desc = "Code action",
				},
				{
					"<leader>ca",
					function()
						vim.lsp.buf.range_code_action()
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
					"<leader>cd",
					function()
						Snacks.picker.lsp_definitions()
					end,
					desc = "Peek definition",
				},
				{
					"<leader>cu",
					function()
						Snacks.picker.lsp_references()
					end,
					desc = "Peek references",
				},
				{
					"<leader>ci",
					function()
						Snacks.picker.lsp_implementations()
					end,
					desc = "Peek implementations",
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
							anchor_bias = "above",
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
