local M = {}

function M.setup()
	function M.setup()
		vim.api.nvim_create_autocmd("BufEnter", {
			callback = function(args)
				vim.defer_fn(function()
					local buf = args.buf
					if vim.api.nvim_buf_is_valid(buf) then
						local name = vim.api.nvim_buf_get_name(buf)
						if name ~= "" and vim.fn.filereadable(name) == 1 then
							vim.cmd("edit")
						end
					end
				end, 10)
			end,
		})
	end
end

return M

