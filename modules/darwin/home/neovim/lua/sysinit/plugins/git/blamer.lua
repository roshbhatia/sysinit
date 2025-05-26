local M = {}

M.plugins = {
	{
		"f-person/git-blame.nvim",
		event = "VeryLazy",
		config = function()
			require("git-blame").setup({
				enabled = true,
				message_template = "  <summary> by <author> in <<sha>>",
				virtual_text_column = 1,
			})

			vim.g.gitblame_highlight_group = "gitblame"
			vim.api.nvim_set_hl(0, "gitblame", {
				fg = "#888888",
				bg = "NONE",
			})
		end,
	},
}

return M
