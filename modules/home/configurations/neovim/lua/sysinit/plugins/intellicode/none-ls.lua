local M = {}

M.plugins = {
	{
		"nvimtools/none-ls.nvim",
		event = "LSPAttach",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			local null_ls = require("null-ls")
			local helpers = require("null-ls.helpers")

			null_ls.setup({
				border = "rounded",
				debounce = 150,
				default_timeout = 5000,
				sources = {
					null_ls.builtins.code_actions.gitsigns,
					null_ls.builtins.code_actions.gitrebase,
					null_ls.builtins.code_actions.impl,
					null_ls.builtins.code_actions.refactoring,
					null_ls.builtins.code_actions.statix,
					null_ls.builtins.code_actions.textlint,
					null_ls.builtins.diagnostics.actionlint,
					null_ls.builtins.diagnostics.checkmake,
					null_ls.builtins.diagnostics.deadnix,
					null_ls.builtins.diagnostics.golangci_lint,
					null_ls.builtins.diagnostics.hadolint,
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
					null_ls.builtins.diagnostics.zsh,
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
				name = "open_link_in_browser",
				method = null_ls.methods.CODE_ACTION,
				filetypes = {},
				generator = {
					fn = function(context)
						local actions = {}
						local node = vim.treesitter.get_node()
						if not node then
							return actions
						end

						local text = vim.treesitter.get_node_text(node, 0)
						if not text then
							return actions
						end

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
						local node = vim.treesitter.get_node()
						if not node then
							return actions
						end

						local text = vim.treesitter.get_node_text(node, 0)
						if not text then
							return actions
						end

						local hex_pattern = "#%x%x%x%x%x%x"
						if text:match(hex_pattern) then
							table.insert(actions, {
								title = "Copy hex color to clipboard",
								action = function()
									vim.fn.setreg("+", text:match(hex_pattern))
									vim.notify("Copied " .. text:match(hex_pattern) .. " to clipboard")
								end,
							})
						end
						return actions
					end,
				},
			})

			-- YAML code actions with yq
			null_ls.register({
				name = "yaml_tools",
				method = null_ls.methods.CODE_ACTION,
				filetypes = { "yaml", "yml" },
				generator = {
					fn = function(context)
						local actions = {}

						table.insert(actions, {
							title = "Format YAML with yq",
							action = function()
								vim.cmd("%!yq eval '.' -")
							end,
						})

						table.insert(actions, {
							title = "Validate YAML syntax",
							action = function()
								vim.cmd("!yq eval '.' % > /dev/null && echo 'Valid YAML' || echo 'Invalid YAML'")
							end,
						})

						table.insert(actions, {
							title = "Convert to JSON",
							action = function()
								vim.cmd("!yq eval -o=json '%' %")
							end,
						})

						return actions
					end,
				},
			})

			-- JSON code actions with jq
			null_ls.register({
				name = "json_tools",
				method = null_ls.methods.CODE_ACTION,
				filetypes = { "json" },
				generator = {
					fn = function(context)
						local actions = {}

						table.insert(actions, {
							title = "Format JSON with jq",
							action = function()
								vim.cmd("%!jq .")
							end,
						})

						table.insert(actions, {
							title = "Compact JSON",
							action = function()
								vim.cmd("%!jq -c .")
							end,
						})

						table.insert(actions, {
							title = "Validate JSON syntax",
							action = function()
								vim.cmd("!jq empty % && echo 'Valid JSON' || echo 'Invalid JSON'")
							end,
						})

						table.insert(actions, {
							title = "Show JSON keys",
							action = function()
								vim.cmd("!jq 'keys' %")
							end,
						})

						return actions
					end,
				},
			})

			-- Helm template actions
			null_ls.register({
				name = "helm_tools",
				method = null_ls.methods.CODE_ACTION,
				filetypes = { "yaml", "yml" },
				generator = {
					fn = function(context)
						local actions = {}
						local bufname = vim.api.nvim_buf_get_name(context.bufnr)

						-- Check if we're in a Helm chart directory
						if
							bufname:match("templates/")
							or bufname:match("Chart.yaml")
							or bufname:match("values.yaml")
						then
							table.insert(actions, {
								title = "Helm template dry-run",
								action = function()
									vim.cmd("!helm template . --dry-run")
								end,
							})

							table.insert(actions, {
								title = "Helm lint chart",
								action = function()
									vim.cmd("!helm lint .")
								end,
							})

							table.insert(actions, {
								title = "Helm template debug",
								action = function()
									vim.cmd("!helm template . --debug")
								end,
							})
						end

						return actions
					end,
				},
			})

			-- Kustomize actions
			null_ls.register({
				name = "kustomize_tools",
				method = null_ls.methods.CODE_ACTION,
				filetypes = { "yaml", "yml" },
				generator = {
					fn = function(context)
						local actions = {}
						local bufname = vim.api.nvim_buf_get_name(context.bufnr)

						-- Check if we're in a directory with kustomization.yaml
						if bufname:match("kustomization.yaml") or vim.fn.filereadable("kustomization.yaml") == 1 then
							table.insert(actions, {
								title = "Kustomize build",
								action = function()
									vim.cmd("!kustomize build .")
								end,
							})

							table.insert(actions, {
								title = "Kustomize build to file",
								action = function()
									vim.cmd("!kustomize build . > output.yaml")
									vim.notify("Kustomize build saved to output.yaml")
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
