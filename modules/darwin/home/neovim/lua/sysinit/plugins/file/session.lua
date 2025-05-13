local M = {}

M.plugins = {
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		config = function()
			require("persistence").setup({
				dir = vim.fn.stdpath("state") .. "/sessions/",
				need = 0, -- always save
				branch = true,
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "PersistenceSavePre",
				callback = function()
					-- Get list of all windows
					local windows = vim.api.nvim_list_wins()
					local empty_buffers = {}

					-- Check each window for empty buffers
					for _, win in ipairs(windows) do
						if vim.api.nvim_win_is_valid(win) then
							local buf = vim.api.nvim_win_get_buf(win)

							-- Check if buffer is loaded and empty
							if vim.api.nvim_buf_is_loaded(buf) then
								local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
								local is_empty = #lines == 1 and lines[1] == ""
								local has_no_name = vim.api.nvim_buf_get_name(buf) == ""

								if is_empty and has_no_name then
									-- Add buffer to our list for deletion
									empty_buffers[buf] = true

									-- Close the window containing this empty buffer
									-- Make sure we don't close the last window
									if #windows > 1 then
										vim.api.nvim_win_close(win, false)
									end
								end
							end
						end
					end

					-- Delete all the empty buffers we found
					for buf, _ in pairs(empty_buffers) do
						if vim.api.nvim_buf_is_valid(buf) then
							vim.api.nvim_buf_delete(buf, { force = false })
						end
					end
				end,
			})
		end,
	},
}

return M
