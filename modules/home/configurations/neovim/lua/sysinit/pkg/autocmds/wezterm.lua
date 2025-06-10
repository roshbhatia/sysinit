local M = {}

function M.setup()
	-- Used to hide wezterm's tab bar on enter
	vim.fn.system('printf "\\033]1337;SetUserVar=IS_NVIM=%s\\007" "true"')

	-- Unset the above
	vim.api.nvim_create_autocmd("VimLeave", {
		callback = function()
			vim.fn.system('printf "\\033]1337;SetUserVar=IS_NVIM=%s\\007" "false"')
		end,
	})
end

return M
