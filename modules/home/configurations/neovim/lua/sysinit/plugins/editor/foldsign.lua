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

					local ns = vim.api.nvim_create_namespace("foldsign")
					vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

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
