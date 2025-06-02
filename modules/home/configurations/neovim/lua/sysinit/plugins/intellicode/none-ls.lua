local M = {}

M.plugins = {
	{
		"nvimtools/none-ls.nvim",
		event = "LazyFile",
		dependencies = { "mason.nvim" },
		opts = function(_, opts)
			local null_ls = require("null-ls")
			local null_ls_methods = require("null-ls.methods")

			opts.sources = {
				null_ls.builtins.completion.spell,
				null_ls.builtins.code_actions.gomodifytags,
				null_ls.builtins.code_actions.impl,
				null_ls.builtins.code_actions.refactoring,
				null_ls.builtins.diagnostics.proselint,
				null_ls.builtins.code_actions.statix,
				null_ls.builtins.formatting.goimports,
				null_ls.builtins.hover.printenv,
				null_ls.builtins.hover.dictionary,
				-- 	-- Fix Issues (Custom Code Action)
				-- 	{
				-- 		name = "fix_code",
				-- 		filetypes = { "javascript", "python", "lua" },
				-- 		method = null_ls_methods.CODE_ACTION,
				-- 		generator = {
				-- 			fn = function(params)
				-- 				return {
				-- 					{
				-- 						title = "Fix code issues",
				-- 						action = function()
				-- 							local fixes = { "Refactor code", "Apply logical fix", "Enhanced logic" }
				-- 							vim.api.nvim_buf_set_lines(
				-- 								params.bufnr,
				-- 								params.row - 1,
				-- 								params.row,
				-- 								false,
				-- 								fixes
				-- 							)
				-- 						end,
				-- 					},
				-- 				}
				-- 			end,
				-- 		},
				-- 	},
				--
				-- 	-- Optimize Code (Custom Code Action)
				-- 	{
				-- 		name = "optimize_code",
				-- 		filetypes = { "javascript", "lua", "golang" },
				-- 		method = null_ls_methods.CODE_ACTION,
				-- 		generator = {
				-- 			fn = function(params)
				-- 				return {
				-- 					{
				-- 						title = "Optimize code",
				-- 						action = function()
				-- 							local optimization = "Optimized package-level imports."
				-- 							vim.api.nvim_buf_set_text(
				-- 								params.bufnr,
				-- 								params.row - 1,
				-- 								0,
				-- 								params.row - 1,
				-- 								100,
				-- 								{ optimization }
				-- 							)
				-- 						end,
				-- 					},
				-- 				}
				-- 			end,
				-- 		},
				-- 	},
				--
				-- 	-- Explain Code (Custom Code Action)
				-- 	{
				-- 		name = "explain_code",
				-- 		filetypes = { "javascript", "lua", "python" },
				-- 		method = null_ls_methods.CODE_ACTION,
				-- 		generator = {
				-- 			fn = function(params)
				-- 				local content = table.concat(params.content, "\n")
				-- 				local explanation = string.format("This piece does the following: %s", content)
				-- 				return {
				-- 					{
				-- 						title = "Explain code using AI (Copilot)",
				-- 						action = function()
				-- 							vim.api.nvim_echo({ { explanation, "Normal" } }, true, {})
				-- 						end,
				-- 					},
				-- 				}
				-- 			end,
				-- 		},
				-- 	},
			}
		end,
	},
}

return M
