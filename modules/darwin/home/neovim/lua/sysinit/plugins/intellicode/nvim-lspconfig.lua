local M = {}

M.plugins = {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{
				"folke/neodev.nvim",
				opts = {},
			}, -- Add b0o/SchemaStore.nvim as dependency
			{ "b0o/SchemaStore.nvim" },
		},
		config = function()
			local lspconfig = require("lspconfig")

			-- Setup diagnostics appearance
			vim.diagnostic.config({
				virtual_text = {
					prefix = "●",
				},
				update_in_insert = true,
				float = {
					source = "always",
				},
			})

			-- Change diagnostic symbols in the sign column
			local signs = {
				Error = " ",
				Warn = " ",
				Hint = " ",
				Info = " ",
			}

			for type, icon in pairs(signs) do
				local hl = "DiagnosticSign" .. type
				vim.fn.sign_define(hl, {
					text = icon,
					texthl = hl,
					numhl = hl,
				})
			end

			-- LSP handlers customization
			vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
				border = "rounded",
			})

			vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
				border = "rounded",
			})

			-- Global LSP mappings
			vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, {
				desc = "Open floating diagnostic message",
			})
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, {
				desc = "Go to previous diagnostic message",
			})
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, {
				desc = "Go to next diagnostic message",
			})
			vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, {
				desc = "Open diagnostics list",
			})

			-- Use an on_attach function to define mappings after the language server attaches
			local on_attach = function(client, bufnr)
				-- LSP mappings
				local map = function(mode, lhs, rhs, desc)
					if desc then
						desc = "LSP: " .. desc
					end
					vim.keymap.set(mode, lhs, rhs, {
						buffer = bufnr,
						desc = desc,
					})
				end

				map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
				map("n", "gd", vim.lsp.buf.definition, "Go to definition")
				map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
				map("n", "gr", vim.lsp.buf.references, "Go to references")
				map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
				map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
				map("n", "<space>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
				map("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
				map("n", "<space>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, "List workspace folders")
				map("n", "<space>D", vim.lsp.buf.type_definition, "Type definition")
				map("n", "<space>rn", vim.lsp.buf.rename, "Rename")
				map("n", "<space>ca", vim.lsp.buf.code_action, "Code action")
				map("n", "<space>f", function()
					vim.lsp.buf.format({
						async = true,
					})
				end, "Format file")

				-- Set autocommands conditional on server capabilities
				if client.server_capabilities.documentHighlightProvider then
					vim.api.nvim_create_augroup("lsp_document_highlight", {
						clear = true,
					})
					vim.api.nvim_create_autocmd("CursorHold", {
						group = "lsp_document_highlight",
						buffer = bufnr,
						callback = vim.lsp.buf.document_highlight,
					})
					vim.api.nvim_create_autocmd("CursorMoved", {
						group = "lsp_document_highlight",
						buffer = bufnr,
						callback = vim.lsp.buf.clear_references,
					})
				end

				-- Disable semantic tokens for rust-analyzer as it can cause issues
				if client.name == "rust_analyzer" then
					client.server_capabilities.semanticTokensProvider = nil
				end
			end

			-- Basic capabilities
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

			-- Enable snippets
			capabilities.textDocument.completion.completionItem.snippetSupport = true

			-- Common language servers setup
			local servers = {
				"lua_ls",
				"ts_ls",
				"pyright",
				"gopls",
				"rust_analyzer",
				"jsonls",
				"bashls",
				"solargraph",
				"html",
				"cssls",
				"tailwindcss",
			}

			for _, lsp in ipairs(servers) do
				lspconfig[lsp].setup({
					on_attach = on_attach,
					capabilities = capabilities,
				})
			end

			-- Special configurations for specific language servers
			lspconfig.lua_ls.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim", "describe", "it", "before_each", "after_each" },
						},
						workspace = {
							library = {
								[vim.fn.expand("$VIMRUNTIME/lua")] = true,
								[vim.fn.stdpath("config") .. "/lua"] = true,
							},
						},
						telemetry = {
							enable = false,
						},
					},
				},
			})

			-- Safely require SchemaStore
			local ok, schemastore = pcall(require, "schemastore")

			-- Use JSON schemas from SchemaStore if available
			lspconfig.jsonls.setup({
				on_attach = on_attach,
				capabilities = capabilities,
				settings = {
					json = {
						schemas = ok and schemastore.json.schemas() or {},
						validate = {
							enable = true,
						},
					},
				},
			})
		end,
	},
}

return M
