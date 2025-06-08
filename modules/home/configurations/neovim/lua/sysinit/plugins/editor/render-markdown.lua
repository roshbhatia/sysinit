local M = {}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		commit = "a1b0988f5ab26698afb56b9c2f0525a4de1195c1",
		dependencies = { "3rd/image.nvim" },
		config = function()
			require("render-markdown").setup({
				anti_conceal = {
					enabled = false,
				},
				code = {
					language_icon = false,
					language_name = false,
				},
				completions = {
					lsp = {
						enabled = true,
					},
				},
				sign = {
					enabled = false,
				},
				quote = {
					repeat_linebreak = true,
				},
			})

			vim.api.nvim_create_autocmd("WinEnter", {
				callback = function()
					local config = vim.api.nvim_win_get_config(0)
					if config.relative ~= "" and vim.bo.filetype == "markdown" then
						vim.opt_local.number = true
					end
				end,
			})
		end,
	},
}

return M
