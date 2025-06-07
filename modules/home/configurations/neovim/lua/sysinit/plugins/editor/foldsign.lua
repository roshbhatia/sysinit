local M = {}

M.plugins = {
	{
		"yaocccc/nvim-foldsign",
		event = "CursorHold",
		config = function()
			require("nvim-foldsign").setup({
				offset = -3,
				foldsigns = {
					open = "*", -- mark the beginning of a fold
					close = "-", -- show a closed fold
					seps = { "│", "┃" }, -- open fold middle marker
				},
				enabled = true,
			})

			vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter" }, {
				pattern = "markdown",
				callback = function(args)
					local bufnr = args.buf
					vim.api.nvim_buf_set_option(bufnr, "signcolumn", "no")
					local ns = vim.api.nvim_create_namespace("spaces")
					vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
					local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
					for i, line in ipairs(lines) do
						vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
							virt_text = { { "  ", "Comment" } }, -- Two spaces (you can customize the style)
							virt_text_pos = "eol", -- Position at the end of the line (you can change this if needed)
						})
					end
				end,
			})
		end,
	},
}
return M
