-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mrjones2014/smart-splits.nvim/refs/heads/master/doc/smart-splits.txt"
local M = {}

M.plugins = {
	{
		"mrjones2014/smart-splits.nvim",
		event = "VeryLazy",
		config = function()
			require("smart-splits").setup({
				ignored_buftypes = {
					"terminal",
					"quickfix",
					"prompt",
					"nofile",
				},
				-- Behavior when cursor is at edge
				at_edge = "stop",
				-- Whether cursor follows swapped buffers
				cursor_follows_swapped_bufs = true,
			})

			-- Hacky way of "locking" the sidebar content

			-- Store the original dimensions of special windows
			local locked_windows = {}

			-- Helper function to check if a buffer is a special sidebar
			local function is_sidebar_buffer(bufnr)
				local ignored_filetypes = {
					"neo-tree",
					"Avante",
					"AvanteSelectedFiles",
					"AvanteInput",
					"AvantePromptInput",
					"codecompanion",
					"snacks_terminal",
				}

				local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
				for _, ignored_ft in ipairs(ignored_filetypes) do
					if ft == ignored_ft then
						return true
					end
				end
				return false
			end

			-- Function to get the filetype of a buffer
			local function get_buffer_filetype(bufnr)
				return vim.api.nvim_buf_get_option(bufnr, "filetype")
			end

			-- Function to save dimensions of all special windows
			local function save_sidebar_dimensions()
				-- Keep track of existing windows first
				local existing_wins = {}
				for _, win_id in ipairs(vim.api.nvim_list_wins()) do
					existing_wins[win_id] = true
				end

				-- Remove any windows that no longer exist
				for win_id, _ in pairs(locked_windows) do
					if not existing_wins[win_id] or not vim.api.nvim_win_is_valid(win_id) then
						locked_windows[win_id] = nil
					end
				end

				-- Add or update existing special windows
				for _, win_id in ipairs(vim.api.nvim_list_wins()) do
					local bufnr = vim.api.nvim_win_get_buf(win_id)
					if is_sidebar_buffer(bufnr) then
						locked_windows[win_id] = {
							width = vim.api.nvim_win_get_width(win_id),
							height = vim.api.nvim_win_get_height(win_id),
							bufname = vim.api.nvim_buf_get_name(bufnr),
							filetype = get_buffer_filetype(bufnr),
						}
					end
				end
			end

			-- Restore dimensions of special windows, except the currently focused one
			local function restore_sidebar_dimensions()
				local current_win = vim.api.nvim_get_current_win()
				local current_buf = vim.api.nvim_get_current_buf()
				local current_ft = get_buffer_filetype(current_buf)

				for win_id, dims in pairs(locked_windows) do
					-- Skip the current window if it's a sidebar window
					if win_id == current_win and is_sidebar_buffer(current_buf) then
						-- Update the stored dimensions for the current window
						locked_windows[win_id].width = vim.api.nvim_win_get_width(win_id)
						locked_windows[win_id].height = vim.api.nvim_win_get_height(win_id)
					else
						-- For non-focused windows, restore dimensions if they've changed
						if vim.api.nvim_win_is_valid(win_id) then
							local current_width = vim.api.nvim_win_get_width(win_id)
							local current_height = vim.api.nvim_win_get_height(win_id)

							-- Only restore if dimensions changed
							if current_width ~= dims.width then
								vim.api.nvim_win_set_width(win_id, dims.width)
							end

							if current_height ~= dims.height then
								vim.api.nvim_win_set_height(win_id, dims.height)
							end
						end
					end
				end
			end

			-- Group windows by filetype for focused group handling
			local function get_windows_by_filetype()
				local windows_by_ft = {}

				for _, win_id in ipairs(vim.api.nvim_list_wins()) do
					local bufnr = vim.api.nvim_win_get_buf(win_id)
					local ft = get_buffer_filetype(bufnr)

					if not windows_by_ft[ft] then
						windows_by_ft[ft] = {}
					end

					table.insert(windows_by_ft[ft], win_id)
				end

				return windows_by_ft
			end

			-- Update dimensions after window switch
			vim.api.nvim_create_autocmd({ "WinEnter" }, {
				callback = function()
					restore_sidebar_dimensions()
					save_sidebar_dimensions()
				end,
			})

			-- Track when special windows are created
			vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
				callback = function(ev)
					if is_sidebar_buffer(ev.buf) then
						-- Wait a bit for the window to set its initial size
						vim.defer_fn(function()
							save_sidebar_dimensions()
						end, 100)
					end
				end,
			})

			-- Set up window resize handling with special behavior for focused sidebars
			vim.api.nvim_create_autocmd({ "WinResized" }, {
				callback = function()
					local current_win = vim.api.nvim_get_current_win()
					local current_buf = vim.api.nvim_get_current_buf()

					-- If we're in a sidebar buffer, allow it to be resized
					if is_sidebar_buffer(current_buf) then
						local current_ft = get_buffer_filetype(current_buf)
						local windows_by_ft = get_windows_by_filetype()

						-- Get all windows with the same filetype as the current buffer
						local windows_of_same_ft = windows_by_ft[current_ft] or {}

						-- Allow resizing of windows with the same filetype by updating their stored dimensions
						for _, win_id in ipairs(windows_of_same_ft) do
							if locked_windows[win_id] then
								locked_windows[win_id].width = vim.api.nvim_win_get_width(win_id)
								locked_windows[win_id].height = vim.api.nvim_win_get_height(win_id)
							end
						end

						-- Restore dimensions for all other sidebars (different filetypes)
						for win_id, dims in pairs(locked_windows) do
							if
								not vim.tbl_contains(windows_of_same_ft, win_id) and vim.api.nvim_win_is_valid(win_id)
							then
								local current_width = vim.api.nvim_win_get_width(win_id)
								local current_height = vim.api.nvim_win_get_height(win_id)

								if current_width ~= dims.width then
									vim.api.nvim_win_set_width(win_id, dims.width)
								end

								if current_height ~= dims.height then
									vim.api.nvim_win_set_height(win_id, dims.height)
								end
							end
						end
					else
						-- If not in a sidebar buffer, restore all sidebar dimensions
						restore_sidebar_dimensions()
					end

					-- After handling, update stored dimensions
					save_sidebar_dimensions()
				end,
			})

			-- For older Neovim versions that don't have WinResized
			if vim.fn.has("nvim-0.10") == 0 then
				vim.api.nvim_create_autocmd({ "VimResized" }, {
					callback = function()
						-- Use the same logic as WinResized
						local current_win = vim.api.nvim_get_current_win()
						local current_buf = vim.api.nvim_get_current_buf()

						if is_sidebar_buffer(current_buf) then
							local current_ft = get_buffer_filetype(current_buf)
							local windows_by_ft = get_windows_by_filetype()
							local windows_of_same_ft = windows_by_ft[current_ft] or {}

							for _, win_id in ipairs(windows_of_same_ft) do
								if locked_windows[win_id] then
									locked_windows[win_id].width = vim.api.nvim_win_get_width(win_id)
									locked_windows[win_id].height = vim.api.nvim_win_get_height(win_id)
								end
							end

							for win_id, dims in pairs(locked_windows) do
								if
									not vim.tbl_contains(windows_of_same_ft, win_id)
									and vim.api.nvim_win_is_valid(win_id)
								then
									local current_width = vim.api.nvim_win_get_width(win_id)
									local current_height = vim.api.nvim_win_get_height(win_id)

									if current_width ~= dims.width then
										vim.api.nvim_win_set_width(win_id, dims.width)
									end

									if current_height ~= dims.height then
										vim.api.nvim_win_set_height(win_id, dims.height)
									end
								end
							end
						else
							restore_sidebar_dimensions()
						end

						save_sidebar_dimensions()
					end,
				})
			end

			-- Create commands to manually lock/unlock sidebars
			vim.api.nvim_create_user_command("LockSidebars", function()
				save_sidebar_dimensions()
				vim.notify("Sidebars locked")
			end, {})

			vim.api.nvim_create_user_command("UnlockSidebars", function()
				locked_windows = {}
				vim.notify("Sidebars unlocked")
			end, {})

			-- Initial save of any sidebar dimensions on startup
			vim.defer_fn(save_sidebar_dimensions, 500)
		end,
		keys = function()
			return {
				{
					"<C-h>",
					'<cmd>lua require("smart-splits").move_cursor_left()<CR>',
					mode = { "n", "i", "v", "t" },
					desc = "Move to left split",
				},
				{
					"<C-j>",
					'<cmd>lua require("smart-splits").move_cursor_down()<CR>',
					mode = { "n", "i", "v", "t" },
					desc = "Move to bottom split",
				},
				{
					"<C-k>",
					'<cmd>lua require("smart-splits").move_cursor_up()<CR>',
					mode = { "n", "i", "v", "t" },
					desc = "Move to top split",
				},
				{
					"<C-l>",
					'<cmd>lua require("smart-splits").move_cursor_right()<CR>',
					mode = { "n", "i", "v", "t" },
					desc = "Move to right split",
				},
				{
					"<M-h>",
					'<cmd>lua require("smart-splits").resize_left()<CR>',
					mode = { "n", "i", "v", "t" },
					desc = "Decrease width of current split",
				},
				{
					"<M-j>",
					'<cmd>lua require("smart-splits").resize_down()<CR>',
					mode = { "n", "i", "v", "t" },
					desc = "Decrease height of current split",
				},
				{
					"<M-k>",
					'<cmd>lua require("smart-splits").resize_up()<CR>',
					mode = { "n", "i", "v", "t" },
					desc = "Increase height of current split",
				},
				{
					"<M-l>",
					'<cmd>lua require("smart-splits").resize_right()<CR>',
					mode = { "n", "i", "v", "t" },
					desc = "Increase width of current split",
				},
				{
					"<leader><S-s>",
					"<cmd>split<CR>",
					mode = { "n", "i", "v", "t" },
					desc = "󰃻 Horizontal",
				},
				{
					"<leader><S-v>",
					"<cmd>vsplit<CR>",
					mode = { "n", "i", "v", "t" },
					desc = "󰃻 Vertical",
				},
			}
		end,
	},
}

return M

