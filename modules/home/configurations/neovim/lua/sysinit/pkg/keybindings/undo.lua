local M = {}

function M.setup()
	vim.keymap.set("n", "u", "g-`[", {
		noremap = true,
		silent = true,
		desc = "Undo to previous state",
	})

	vim.keymap.set("n", "U", "g+`[", {
		noremap = true,
		silent = true,
		desc = "Redo to next state",
	})
end

return M

