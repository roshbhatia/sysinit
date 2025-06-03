local M = {}

local copilot_shared = {
	command = "goose",
	format = "raw",
	to_stdin = false,
	to_temp_file = true,
	filetypes = { "*" },
}

local copilot_actions = {
	{
		name = "fix_code",
		prompt = "You are an inline assistant copilot used to generate code actions. Your directive is to fix the code based on LSP information and context. YOU MUST wrap the explanation language-native block comments",
		details = "Generates fixes based on detected issues in the current code.",
		title = "Fix code with Copilot",
	},
	{
		name = "optimize_code",
		prompt = "You are an inline assistant copilot used to generate code actions. Your directive is to optimize the code based on best practices and context. YOU MUST wrap the explanation language-native block comments",
		details = "Provides code improvements based on best practices and performance considerations.",
		title = "Optimize code with Copilot",
	},
	{
		name = "explain_code",
		prompt = "You are an inline assistant copilot used to generate code actions. Your directive is to explain the code based on context. YOU MUST wrap the explanation language-native block comments.",
		details = "Analyzes and comments on code functionality for better comprehension.",
		title = "Explain code with Copilot",
	},
}

M.plugins = {
	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		opts = function(_, opts)
			local null_ls = require("null-ls")
			local null_ls_methods = require("null-ls.methods")

			opts.sources = vim.list_extend(opts.sources or {}, {
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
			})

			local helpers = require("null-ls.helpers")
			for _, action in ipairs(copilot_actions) do
				table.insert(
					opts.sources,
					helpers.make_builtin({
						method = null_ls_methods.CODE_ACTION,
						filetypes = {},
						generator = helpers.generator_factory({
							args = function(params)
								return {
									"run",
									"--no-session",
									"-i",
									"-",
									action.prompt,
									"$TEXT",
								}
							end,
							ignore_stderr = true,
							timeout = 10000,
							use_cache = true,
							on_output = function(params, done)
								done({
									{
										title = action.title,
										action = function()
											local orig = params.bufname or "$FILENAME"
											local tmp = params.temp_path or ""
											vim.cmd("tabnew | diffthis")
											vim.cmd("edit " .. orig)
											vim.cmd("vsplit " .. tmp)
											vim.cmd("wincmd l | diffthis")
										end,
										details = action.details,
									},
								})
							end,
						}),
					})
				)
			end
		end,
	},
}

return M
