-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mfussenegger/nvim-lint/master/doc/lint.txt"
local M = {}

M.plugins = {
	{
		"mfussenegger/nvim-lint",
		dependencies = { "WhoIsSethDaniel/mason-tool-installer.nvim" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				javascript = { "eslint" },
				typescript = { "eslint" },
				javascriptreact = { "eslint" },
				typescriptreact = { "eslint" },
				go = { "golangcilint" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				zsh = { "shellcheck" },
				json = { "jsonlint" },
				markdown = { "markdownlint" },
				terraform = { "tflint" },
			}

			lint.linters.pylint.args = {
				"--output-format=text",
				"--score=no",
				"--msg-template='{line}:{column}:{category}:{msg} ({symbol})'",
			}

			lint.linters.shellcheck.args = { "--format=gcc", "--external-sources", "--shell=bash" }

			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},
}

return M
