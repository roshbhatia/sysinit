local M = {}

M.plugins = {
	{
		"f-person/git-blame.nvim",
		event = "VeryLazy",
		config = function()
			require("gitblame").setup({
				enabled = true,
				message_template = "<summary> by <author> in <<sha>>",
			})

			vim.g.gitblame_highlight_group = "gitblame"
			vim.api.nvim_set_hl(0, "gitblame", {
				fg = "#888888",
				bg = vim.api.nvim_get_hl_by_name("CursorLine", true).background,
			})
		end,
	},
}

return M
