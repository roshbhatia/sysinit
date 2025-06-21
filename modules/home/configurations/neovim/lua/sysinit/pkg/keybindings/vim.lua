local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>q", function()
		local answer = vim.fn.confirm("Are you sure you want to quit all?", "&Yes\n&No", 2)
		if answer == 1 then
			vim.cmd("qa!")
		end
	end, {
		noremap = true,
		silent = true,
		desc = "Quit with confirmation",
	})

	vim.keymap.set("i", "jj", "<ESC>", {
		noremap = true,
		silent = true,
		desc = "Escape Insert Mode",
	})
end

return M
