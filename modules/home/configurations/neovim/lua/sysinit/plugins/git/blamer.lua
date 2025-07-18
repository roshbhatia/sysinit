local M = {}

M.plugins = {
	{
		"f-person/git-blame.nvim",
		cmd = {
			"GitBlameCopyCommitURL",
			"GitBlameOpenFileURL",
		},
		config = function()
			require("gitblame").setup({
				enabled = true,
				message_template = "<summary> by <author> in <<sha>>",
			})

			vim.g.gitblame_display_virtual_text = 0
		end,
		keys = function()
			return {
				{
					"<localleader>gbc",
					"<CMD>GitBlameCopyCommitURL<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Copy blame URL",
				},
				{
					"<localleader>gbo",
					"<CMD>GitBlameOpenFileURL<CR>",
					mode = "n",
					noremap = true,
					silent = true,
					desc = "Open blame URL",
				},
			}
		end,
	},
}

return M
