local M = {}

function M.setup()
	vim.opt.mouse = "a"
	vim.o.mousemoveevent = true
	vim.opt.clipboard = "unnamedplus"
	vim.opt.number = true
	vim.opt.relativenumber = true
	vim.opt.signcolumn = "yes:2"
	vim.opt.numberwidth = 6
	vim.opt.fillchars:append({ eob = " " })
	vim.opt.cursorline = true
	vim.opt.spell = false
end

return M
