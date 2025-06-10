local M = {}

function M.setup()
	vim.api.nvim_set_keymap("n", "m", "<Nop>", {
		noremap = true,
		silent = true,
	})

	vim.api.nvim_set_keymap("v", "m", "<Nop>", {
		noremap = true,
		silent = true,
	})
end

return M
