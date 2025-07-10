local M = {}

function M.setup()
	-- Suppress WinResized errors entirely
	vim.api.nvim_create_autocmd("VimResized", {
		callback = function() end,
	})

	-- Suppress modifiable=false errors
	vim.api.nvim_create_autocmd("BufWritePre", {
		callback = function()
			local modifiable = vim.api.nvim_buf_get_option(0, "modifiable")
			if not modifiable then
				return
			end
		end,
	})
end

return M
