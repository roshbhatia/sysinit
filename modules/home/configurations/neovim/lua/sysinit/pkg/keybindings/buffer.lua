local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>x", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent x")
	end, {
		noremap = true,
		silent = true,
		desc = "Close buffer",
	})

	vim.keymap.set("n", "<leader>w", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
		vim.cmd("silent x")
	end, {
		noremap = true,
		silent = true,
		desc = "Write and close buffer",
	})

	vim.keymap.set("n", "<leader>s", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
	end, {
		noremap = true,
		silent = true,
		desc = "Write",
	})

	vim.keymap.set("n", "<localleader>s", function()
		vim.cmd("noautocmd write")
	end, {
		noremap = true,
		silent = true,
		desc = "Write (no format)",
	})

	vim.keymap.set("n", "<localleader>bn", function()
		vim.cmd("bnext")
	end, {
		noremap = true,
		silent = true,
		desc = "Next buffer",
	})

	vim.keymap.set("n", "<localleader>bp", function()
		vim.cmd("bprevious")
	end, {
		noremap = true,
		silent = true,
		desc = "Previous buffer",
	})
end

return M

