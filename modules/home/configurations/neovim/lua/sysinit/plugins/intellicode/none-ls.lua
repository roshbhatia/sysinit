local M = {}

M.plugins = {
	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		opts = function(_, opts)
			local null_ls = require("null-ls")
			local null_ls_methods = require("null-ls.methods")

			opts.sources = {
				null_ls.builtins.code_actions.gomodifytags,
				null_ls.builtins.code_actions.impl,
				null_ls.builtins.code_actions.refactoring,
				null_ls.builtins.code_actions.statix,
				null_ls.builtins.code_actions.textlint,
				null_ls.builtins.completion.spell,
				null_ls.builtins.diagnostics.markdownlint,
				null_ls.builtins.diagnostics.proselint,
				null_ls.builtins.diagnostics.yamllint,
				null_ls.builtins.formatting.goimports,
				null_ls.builtins.hover.dictionary,
				null_ls.builtins.hover.printenv,
				{
					name = "fix_code",
					method = null_ls_methods.CODE_ACTION,
					generator = {
						fn = function(params)
							return {
								{
									title = "Fix code with Copilot",
									action = function()
										vim.cmd("CopilotChatFix")
									end,
								},
							}
						end,
					},
				},

				{
					name = "optimize_code",
					method = null_ls_methods.CODE_ACTION,
					generator = {
						fn = function(params)
							return {
								{
									title = "Optimize code with Copilot",
									action = function()
										vim.cmd("CopilotChatOptimize")
									end,
								},
							}
						end,
					},
				},
				{
					name = "explain_code",
					method = null_ls_methods.CODE_ACTION,
					generator = {
						fn = function(params)
							local content = table.concat(params.content, "\n")
							local explanation = string.format("This piece does the following: %s", content)
							return {
								{
									title = "Explain code with Copilot",
									action = function()
										vim.cmd("CopilotChatExplain")
									end,
								},
							}
						end,
					},
				},
			}
		end,
	},
}

return M
