local M = {}

M.plugins = {
	{
		"nvimtools/none-ls.nvim",
		event = "LSPAttach",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local null_ls = require("null-ls")
			local helpers = require("null-ls.helpers")
			local ts_utils = require("nvim-treesitter.ts_utils")

			null_ls.setup({
				border = "rounded",
				sources = {
					null_ls.builtins.code_actions.gomodifytags,
					null_ls.builtins.code_actions.impl,
					null_ls.builtins.code_actions.refactoring,
					null_ls.builtins.code_actions.statix,
					null_ls.builtins.code_actions.textlint,
					null_ls.builtins.diagnostics.actionlint,
					null_ls.builtins.diagnostics.checkmake,
					null_ls.builtins.diagnostics.deadnix,
					null_ls.builtins.diagnostics.golangci_lint,
					null_ls.builtins.diagnostics.proselint,
					null_ls.builtins.diagnostics.staticcheck,
					null_ls.builtins.diagnostics.terraform_validate,
					null_ls.builtins.diagnostics.tfsec,
					null_ls.builtins.diagnostics.yamllint.with({
						args = {
							"-d",
							'{"rules": {"line-length": "disable", "document-start": "disable", "comments": "disable"}}',
							"--format",
							"parsable",
							"-",
						},
					}),
					null_ls.builtins.diagnostics.vale,
					null_ls.builtins.diagnostics.zsh,
					null_ls.builtins.formatting.gofmt,
					null_ls.builtins.formatting.gofumpt,
					null_ls.builtins.formatting.goimports,
					null_ls.builtins.formatting.markdownlint,
					null_ls.builtins.formatting.nixfmt,
					null_ls.builtins.formatting.prettierd,
					null_ls.builtins.formatting.shfmt,
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.yapf,
					null_ls.builtins.hover.dictionary,
					null_ls.builtins.hover.printenv,
				},
			})

			local copilot_actions = {
				{
					title = "Explain code with Copilot",
					cmd = "CopilotChatExplain",
				},
			}

			if not vim.uv.fs_stat(vim.fn.expand("~/.nocopilot")) then
				for _, action in ipairs(copilot_actions) do
					null_ls.register({
						method = null_ls.methods.CODE_ACTION,
						filetypes = {},
						generator = {
							fn = function(context)
								return {
									{
										title = action.title,
										action = function()
											vim.cmd(action.cmd)
										end,
									},
								}
							end,
						},
					})
				end
			end

			null_ls.register({
				method = null_ls.methods.CODE_ACTION,
				filetypes = {
					"markdown",
				},
				generator = {
					fn = function(context)
						return {
							{
								title = "Toggle markdown browser preview",
								action = function()
									vim.cmd("MarkdownPreviewToggle")
								end,
							},
						}
					end,
				},
			})

			null_ls.register({
				name = "open_link_in_browser",
				method = null_ls.methods.CODE_ACTION,
				filetypes = {},
				generator = {
					fn = function(context)
						local actions = {}
						local node = ts_utils.get_node_at_cursor()
						if not node then
							return actions
						end

						local text = ts_utils.get_node_text(node)[1] or ""
						-- Pattern to match an http/https URL
						local url_pattern = "https?://[%w-_%.%?%.:/%+=&]+"
						local url = text:match(url_pattern)
						if url then
							table.insert(actions, {
								title = "Open link in browser",
								action = function()
									vim.fn.jobstart({ "open", url }, { detach = true })
								end,
							})
						end
						return actions
					end,
				},
			})

			null_ls.register({
				name = "hex_color_tools",
				method = null_ls.methods.CODE_ACTION,
				filetypes = {},
				generator = {
					fn = function(context)
						local actions = {}
						local node = ts_utils.get_node_at_cursor()
						if not node then
							return actions
						end

						local text = ts_utils.get_node_text(node)[1] or ""
						local hex_pattern = "#%x%x%x%x%x%x"
						if text:match(hex_pattern) then
							table.insert(actions, {
								title = "Generate color shade palette",
								action = function()
									vim.cmd("Shades")
								end,
							})

							table.insert(actions, {
								title = "Generate color hue variations",
								action = function()
									vim.cmd("Huefy")
								end,
							})
						end
						return actions
					end,
				},
			})
		end,
	},
}

return M

