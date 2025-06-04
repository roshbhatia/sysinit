local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function(args)
			local buf = args.buf
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" and vim.fn.filereadable(name) == 1 then
				vim.cmd("edit")
			end
		end,
	})
end

return M
