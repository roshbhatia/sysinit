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

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.opt_local.foldcolumn = "0"
				end,
			})
		end,
	},
}
return M

