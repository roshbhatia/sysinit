local M = {}

M.plugins = {
	{
		"nvimtools/none-ls.nvim",
		event = "LSPAttach",
		dependencies = {
			"nvim-lua/plenary.nvim",
<<<<<<< HEAD
=======
										title = "Generate color hue variations",
										action = function()
											vim.cmd("Huefy")
											vim.notify("Generated color hue variations", vim.log.levels.INFO)
										end,
									},
>>>>>>> Snippet
		},
		config = function()
			local null_ls = require("null-ls")
			local helpers = require("null-ls.helpers")

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
					-- null_ls.builtins.diagnostics.vale,
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
				name = "hex_color_tools",
				method = null_ls.methods.CODE_ACTION,
				filetypes = { "*" },
				generator = {
					fn = function(context)
						local actions = {}
						local hex_pattern = "#%x%x%x%x%x%x"
						local row = context.range.row
						local line = context.content[row - context.range.row + 1] or ""
						local col = vim.api.nvim_win_get_cursor(0)[2] + 1
						local start_idx, end_idx = line:find(hex_pattern)
						while start_idx do
							if col >= start_idx and col <= end_idx then
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
								break
							end
							start_idx, end_idx = line:find(hex_pattern, end_idx + 1)
						end

						return actions
					end,
				},
			})
		end,
	},
}

return M

