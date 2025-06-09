local M = {}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		commit = "6f5a4c36d9383b2a916facaa63dcd573afa11ee8",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
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

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function(args)
					local bufname = vim.api.nvim_buf_get_name(args.buf)
					if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
						vim.api.nvim_set_hl(0, "Normal", { link = "NormalOpaque" })
						vim.api.nvim_set_hl(0, "NormalNC", { link = "NormalNCOpaque" })
					end
				end,
			})
		end,
	},
}

return M

