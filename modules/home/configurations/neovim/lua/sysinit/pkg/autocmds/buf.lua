local M = {}

function M.setup()
	-- Suppress WinResized errors entirely
	vim.api.nvim_create_autocmd("VimResized", {
		callback = function() end,
	})
end

return M

