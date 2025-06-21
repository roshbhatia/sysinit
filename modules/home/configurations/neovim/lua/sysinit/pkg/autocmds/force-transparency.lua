local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("WinNew", {
		callback = function()
			vim.defer_fn(function()
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
					if ok and cfg.relative ~= "" then -- only floating windows
						pcall(vim.api.nvim_set_option_value, "winblend", 0, { win = win })
					end
				end
			end, 10)
		end,
	})
end

return M
