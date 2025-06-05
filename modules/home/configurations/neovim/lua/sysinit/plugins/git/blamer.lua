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

			local cursor_line_bg = vim.api.nvim_get_hl_by_name("CursorLine", true).background
			local normal_fg = vim.api.nvim_get_hl_by_name("Normal", true).foreground
			vim.g.gitblame_highlight_group = "gitblame"

			vim.api.nvim_set_hl(0, "gitblame", {
				fg = vim.fn.synIDattr(vim.fn.hlID("Comment"), "fg") or normal_fg,
				bg = cursor_line_bg or "NONE",
			})
		end,
	},
}

return M
