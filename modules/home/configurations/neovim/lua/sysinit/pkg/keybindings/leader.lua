local M = {}

function M.setup()
	vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", {
		noremap = true,
		silent = true,
	})
end

return M
