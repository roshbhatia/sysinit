-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/numToStr/Comment.nvim/refs/heads/master/doc/Comment.txt"
local M = {}

M.plugins = {
	{
		"echasnovski/mini.comment",
		event = "BufReadPost",
		version = "*",
	},
}

return M
