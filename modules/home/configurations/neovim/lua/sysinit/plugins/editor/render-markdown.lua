local M = {}

local markdown_filetypes = {
	"markdown",
}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		commit = "a1b0988f5ab26698afb56b9c2f0525a4de1195c1",
		dependencies = { "3rd/image.nvim" },
		ft = markdown_filetypes,
		config = function()
			require("render-markdown").setup({
				anti_conceal = {
					enabled = false,
				},
				code = {
					language_icon = false,
					language_name = false,
				},
				file_types = markdown_filetypes,
				render_modes = true,
				sign = {
					enabled = false,
				},
				completions = {
					lsp = {
						enabled = true,
					},
				},
			})

			vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter" }, {
				pattern = "markdown",
				callback = function(args)
					local winid = vim.api.nvim_get_current_win()
					vim.api.nvim_set_option_value("number", false, { win = winid })
					vim.api.nvim_set_option_value("relativenumber", false, { win = winid })
					vim.api.nvim_set_option_value("foldcolumn", "0", { win = winid })
				end,
			})
		end,
	},
}

return M
