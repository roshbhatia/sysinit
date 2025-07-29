local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			vim.cmd("redir > ~/.cache/nvim/last-run-messages.log")
			vim.cmd("silent messages")
			vim.cmd("redir END")
		end,
	})
end

return M

