-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/numToStr/Comment.nvim/refs/heads/master/doc/Comment.txt"
local M = {}

M.plugins = {
	{
		"echasnovski/mini.comment",
		commit = "6e1f9a8ebbf6f693fa3787ceda8ca3bf3cb6aec7",
		event = "BufReadPost",
		version = "*",
	},
}

return M
