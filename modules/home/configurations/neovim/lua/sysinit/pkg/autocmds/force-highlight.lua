local M = {}

function M.setup()
	vim.api.nvim_create_autocmd({ "LspAttach", "FileType" }, {
		callback = function(args)
			local ft = vim.bo[args.buf].filetype
			vim.api.nvim_buf_call(args.buf, function()
				vim.cmd("silent! edit!")
			end)
			vim.api.nvim_buf_call(args.buf, function()
				vim.cmd("silent! edit!")
			end)
			vim.api.nvim_buf_call(args.buf, function()
				vim.cmd("silent! edit!")
			end)
		end,
	})
end

return M
