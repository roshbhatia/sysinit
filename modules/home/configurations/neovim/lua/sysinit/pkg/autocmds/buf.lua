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
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.api.nvim_buf_get_option(buf, "filetype")

			-- Check if it's a floating window or specific filetype
			local special_filetypes = {
				"oil",
				"avante",
				"codecompanion",
				"opencode",
				"neo-tree",
				"trouble",
				"quickfix",
				"help",
				"alpha",
			}

			local should_disable = config.relative ~= "" or vim.tbl_contains(special_filetypes, ft)

			if should_disable then
				vim.wo[win].foldcolumn = "0"
				vim.wo[win].signcolumn = "no"
			end
		end,
	})
end

return M
