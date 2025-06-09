local M = {}

-- Track buffers that have already been processed
local processed_buffers = {}

function M.setup()
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		callback = function(args)
			local buf = args.buf

			if processed_buffers[buf] then
				return
			end

			local bufname = vim.api.nvim_buf_get_name(buf)
			if bufname == "" or not vim.fn.filereadable(bufname) then
				return
			end

			processed_buffers[buf] = true

			vim.api.nvim_buf_call(buf, function()
				vim.cmd("silent! edit!")
			end)

			vim.api.nvim_create_autocmd("BufDelete", {
				buffer = buf,
				once = true,
				callback = function()
					processed_buffers[buf] = nil
				end,
			})
		end,
	})
end

return M
