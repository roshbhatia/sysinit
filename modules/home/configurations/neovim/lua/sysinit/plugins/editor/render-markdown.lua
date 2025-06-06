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
				file_types = markdown_filetypes,
				render_modes = true,
				sign = {
					enabled = false,
				},
			})

			-- Completely disable signcolumn on markdown files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.opt_local.signcolumn = "no"
				end,
			})

			vim.api.nvim_create_autocmd("WinEnter", {
				callback = function()
					local config = vim.api.nvim_win_get_config(0)
					-- Check if the window is floating and its filetype is markdown
					if config.relative ~= "" and vim.bo.filetype == "markdown" then
						vim.opt_local.signcolumn = "no"
					end
				end,
			})
		end,
	},
}

return M
