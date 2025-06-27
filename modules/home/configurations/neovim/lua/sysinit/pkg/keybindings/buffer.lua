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

	vim.keymap.set("n", "<leader>s", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
	end, {
		noremap = true,
		silent = true,
		desc = "Write",
	})

	vim.keymap.set("n", "<leader>S", function()
		vim.cmd("noautocmd write")
	end, {
		noremap = true,
		silent = true,
		desc = "Write (No Format)",
	})

	vim.keymap.set("n", "<leader>w", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
		vim.cmd("silent quit!")
	end, {
		noremap = true,
		silent = true,
		desc = "Write and close",
	})

	vim.keymap.set("n", "<leader>bn", function()
		vim.cmd("bnext")
	end, {
		noremap = true,
		silent = true,
		desc = "Next",
	})

	vim.keymap.set("n", "<leader>bN", function()
		vim.cmd("bprevious")
	end, {
		noremap = true,
		silent = true,
		desc = "Previous",
	})
end

return M
