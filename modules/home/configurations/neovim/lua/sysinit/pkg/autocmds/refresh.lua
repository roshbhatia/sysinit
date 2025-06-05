local M = {}

function M.setup()
	-- bizzare! but something in here is needed to force syntax highlighting
	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function(args)
			-- technically on by default, but forcing doesn't hurt
			vim.cmd("syntax on")
			vim.defer_fn(function()
				local buf = args.buf
				if vim.api.nvim_buf_is_valid(buf) then
					-- mapped to :edit, but vim.cmd("edit") doesnt seem to do anything in here
					-- so we're proxying it through the keybinding
					vim.cmd("normal \\<leader>rr")
				end
			end, 100)
		end,
	})
end

return M

