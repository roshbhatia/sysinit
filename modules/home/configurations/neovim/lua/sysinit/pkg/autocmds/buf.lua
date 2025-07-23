local M = {}

function M.setup()
	-- Suppress WinResized errors entirely
	vim.api.nvim_create_autocmd("VimResized", {
		callback = function() end,
	})

	-- Disable fold signs/gutters in floating windows
	vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "FileType" }, {
		callback = function()
			local win = vim.api.nvim_get_current_win()
			local config = vim.api.nvim_win_get_config(win)
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })

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
				"TelescopePrompt",
				"TelescopeResults",
				"notify",
				"noice",
				"mason",
				"lazy",
			}

			local is_floating = config.relative ~= ""
			local is_special_ft = vim.tbl_contains(special_filetypes, ft)

			if is_floating or is_special_ft then
				vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })
				vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
				vim.api.nvim_set_option_value("number", false, { win = win })
				vim.api.nvim_set_option_value("relativenumber", false, { win = win })
			end
		end,
	})
end

return M
