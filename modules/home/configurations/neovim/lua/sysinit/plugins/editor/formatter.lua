local M = {}

M.plugins = {
	{
		"stevearc/conform.nvim",
		event = "BufEnter",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					bash = {
						"shfmt",
					},
					css = {
						"prettier",
						"prettierd",
						stop_after_first = true,
					},
					go = {
						"goimports",
						"gofmt",
					},
					html = {
						"prettier",
						"prettierd",
						stop_after_first = true,
					},
					javascript = {
						"prettier",
						"prettierd",
						stop_after_first = true,
					},
					json = {
						"jq",
					},
					lua = {
						"stylua",
					},
					markdown = {
						"prettier",
						"prettierd",
						stop_after_first = true,
					},
					nix = {
						"nixfmt",
					},
					python = {
						"autopep8",
					},
					rust = {
						"rustfmt",
					},
					sh = {
						"shfmt",
					},
					terraform = {
						"terraform_fmt",
					},
					typescript = {
						"prettier",
						"prettierd",
						stop_after_first = true,
					},
					yaml = {
						"yq",
					},
					zsh = {
						"shfmt",
					},
				},
				stop_after_first = false,
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

