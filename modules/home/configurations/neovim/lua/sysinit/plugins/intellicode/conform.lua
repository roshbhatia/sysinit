local M = {}

M.plugins = {
	{
		"stevearc/conform.nvim",
		event = "BufEnter",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "black" },
					javascript = {
						"prettierd",
						"prettier",
						stop_after_first = true,
					},
					typescript = {
						"prettierd",
						"prettier",
						stop_after_first = true,
					},
					go = {
						"goimports",
						"gofmt",
					},
					json = {
						"prettierd",
						"prettier",
						stop_after_first = true,
					},
					yaml = {
						"prettierd",
						"prettier",
						stop_after_first = true,
					},
					markdown = {
						"markdownlint",
						"prettierd",
						"prettier",
						stop_after_first = true,
					},
					html = {
						"prettierd",
						"prettier",
						stop_after_first = true,
					},
					css = {
						"prettierd",
						"prettier",
						stop_after_first = true,
					},
					sh = { "shfmt" },
					bash = { "shfmt" },
					zsh = { "shfmt" },
					rust = { "rustfmt" },
					nix = { "nixfmt" },
				},
				notify_on_error = false,
				format_on_save = function(bufnr)
					if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
						return
					end
					return {
						timeout_ms = 500,
						lsp_fallback = true,
					}
				end,
			})
		end,
	},
}

return M
