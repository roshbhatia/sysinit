local M = {}

function M.setup()
	vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", {
		noremap = true,
		silent = true,
	})

	vim.keymap.set("n", "<leader><leader>", ":", {
		noremap = true,
		silent = true,
		desc = "Enter command-line mode",
	})
end

return M
