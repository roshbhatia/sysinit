local M = {}

M.plugins = {
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
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
