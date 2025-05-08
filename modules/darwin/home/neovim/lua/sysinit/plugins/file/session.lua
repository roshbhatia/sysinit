local M = {}

M.plugins = { {
	"folke/persistence.nvim",
	event = "BufReadPre",
	opts = {},
} }

return M
