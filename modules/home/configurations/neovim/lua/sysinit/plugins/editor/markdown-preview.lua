local M = {}

M.plugins = {
	{
		"iamcco/markdown-preview.nvim",
		cmd = {
			"MarkdownPreviewToggle",
			"MarkdownPreview",
			"MarkdownPreviewStop",
		},
		build = "cd app && yarn install",
		init = function()
			vim.g.mkdp_filetypes = {
				"markdown",
			}
		end,
		ft = {
			"markdown",
		},
		keys = function()
			return {
				{
					"<localleader>p",
					"<cmd>MarkdownPreviewToggle<cr>",
					desc = "Toggle Markdown Preview",
					ft = "markdown",
				},
			}
		end,
	},
}

return M

