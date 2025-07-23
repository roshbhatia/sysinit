local M = {}

function M.setup()
	-- Suppress WinResized errors entirely
	vim.api.nvim_create_autocmd("VimResized", {
		callback = function() end,
	})

	-- Disable fold signs/gutters in floating windows and special filetypes
	vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "FileType", "BufEnter" }, {
		callback = function()
			local win = vim.api.nvim_get_current_win()
			local config = vim.api.nvim_win_get_config(win)
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })

			-- Special filetypes that should have clean UI
			local special_filetypes = {
				"oil",
				"oil_preview",
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
				"dapui_watches",
				"dapui_breakpoints",
				"dapui_scopes",
				"dapui_console",
				"dapui_stacks",
				"dap-repl",
			}

			local is_floating = config.relative ~= ""
			local is_special_ft = vim.tbl_contains(special_filetypes, ft)

			if is_floating or is_special_ft then
				-- Safely set options, checking if they exist
				pcall(function()
					vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })
					vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
					vim.api.nvim_set_option_value("number", false, { win = win })
					vim.api.nvim_set_option_value("relativenumber", false, { win = win })
				end)
			end
		end,
	})

	-- Additional autocmd specifically for Oil preview windows
	vim.api.nvim_create_autocmd("User", {
		pattern = "OilEnter",
		callback = function()
			local wins = vim.api.nvim_list_wins()
			for _, win in ipairs(wins) do
				local buf = vim.api.nvim_win_get_buf(win)
				local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
				local config = vim.api.nvim_win_get_config(win)
				
				if ft == "oil" or config.relative ~= "" then
					pcall(function()
						vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })
						vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
					end)
				end
			end
		end,
	})
end

return M
