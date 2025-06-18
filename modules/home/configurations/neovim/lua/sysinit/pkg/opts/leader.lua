local M = {}

function M.setup()
	vim.g.mapleader = " "
	vim.keymap.del("n", "`") -- Unbind backtick, we don't use normal marks.
	vim.g.maplocalleader = "`"
end

return M
