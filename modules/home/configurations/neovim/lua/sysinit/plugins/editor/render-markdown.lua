local M = {}

local markdown_filetypes = {
	"markdown",
	"Avante",
	"codecompanion",
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
				file_types = markdown_filetypes,
				render_modes = true,
				latex = {
					enabled = false,
				},
				html = {
					enabled = false,
				},
			})

			-- Signcolumn on markdown files sometimes causes issues
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.opt_local.signcolumn = "yes:2"
				end,
			})
		end,
	},
}

return M
