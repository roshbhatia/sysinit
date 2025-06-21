local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("WinNew", {
		callback = function(args)
			vim.defer_fn(function()
				local winid = args.win
				local cfg = vim.api.nvim_win_get_config(winid)
				if cfg and cfg.relative ~= "" then
					pcall(vim.api.nvim_set_option_value, "winblend", 0, { win = winid })
				end
			end, 10)
		end,
	})
end

return M

