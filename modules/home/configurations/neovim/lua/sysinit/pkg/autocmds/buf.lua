local M = {}

function M.setup()
	-- Suppress WinResized errors entirely
	vim.api.nvim_create_autocmd("VimResized", {
		callback = function() end,
	})

	-- Disable fold signs/gutters in floating windows
	vim.api.nvim_create_autocmd("WinEnter", {
		callback = function()
			local win = vim.api.nvim_get_current_win()
			local config = vim.api.nvim_win_get_config(win)
			
			-- Check if it's a floating window
			if config.relative ~= "" then
				vim.wo[win].foldcolumn = "0"
				vim.wo[win].signcolumn = "no"
			end
		end,
	})
end

return M
