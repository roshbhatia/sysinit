local M = {}

function M.setup()
	vim.opt.shortmess:append("A")
	vim.o.autoread = true
	vim.api.nvim_create_autocmd({
		"FocusGained",
		"BufEnter",
		"CursorHold",
		"CursorHoldI",
	}, {
		pattern = "*",
		callback = function()
			if vim.fn.mode() ~= "c" then
				vim.cmd("checktime")
			end
		end,
	})
	vim.api.nvim_create_autocmd("FileChangedShellPost", {
		pattern = "*",
		callback = function()
			vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN)
		end,
	})
end

return M
