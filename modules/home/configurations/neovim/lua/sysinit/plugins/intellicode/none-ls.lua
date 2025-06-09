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
					null_ls.builtins.diagnostics.markdownlint,
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
					null_ls.builtins.hover.dictionary,
					null_ls.builtins.hover.printenv,
				},
			})

			local copilot_actions = {
				{
					title = "Fix diagnostic with Copilot",
					cmd = "CopilotChatFix",
				},
				{
					title = "Explain code with Copilot",
					cmd = "CopilotChatExplain",
				},
				{
					title = "Optimize code with Copilot",
					cmd = "CopilotChatOptimize",
				},
			}

			null_ls.register({
				name = "golangci_lint_fix",
				method = methods.CODE_ACTION,
				filetypes = { "go" },
				generator = {
					fn = function(params)
						local has_fixable = false
						for _, diag in ipairs(params.diagnostics) do
							if diag.source == "golangci-lint" and diag.row == params.row then
								has_fixable = true
								break
							end
						end

						if not has_fixable then
							return nil
						end

						return {
							{
								title = "Run golangci-lint --fix",
								action = function()
									local cmd = "golangci-lint run --fix " .. vim.fn.shellescape(params.bufname)
									vim.fn.jobstart(cmd, {
										stdout_buffered = true,
										on_stdout = function(_, data)
											if data then
												vim.notify(
													table.concat(data, "\n"),
													vim.log.levels.INFO,
													{ title = "golangci-lint" }
												)
											end
										end,
										on_stderr = function(_, data)
											if data and data[1] ~= "" then
												vim.notify(
													table.concat(data, "\n"),
													vim.log.levels.ERROR,
													{ title = "golangci-lint error" }
												)
											end
										end,
										on_exit = function()
											vim.cmd("edit!")
										end,
									})
								end,
							},
						}
					end,
				},
			})

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
		end,
	},
}

return M
