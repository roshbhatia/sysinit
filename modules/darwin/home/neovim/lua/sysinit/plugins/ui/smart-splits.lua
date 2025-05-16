-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mrjones2014/smart-splits.nvim/refs/heads/master/doc/smart-splits.txt"
local M = {}

local ignored_filetypes = {
	"neo-tree",
	"Avante",
	"AvanteSelectedFiles",
	"AvanteInput",
	"AvantePromptInput",
	"codecompanion",
	"snacks_terminal",
}

local locked_windows = {}

-- Helper function to check if a buffer is a special sidebar
local function is_sidebar_buffer(bufnr)
	local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
	for _, ignored_ft in ipairs(ignored_filetypes) do
		if ft == ignored_ft then
			return true
		end
	end
	return false
end

-- Function to save dimensions of all special windows
local function save_sidebar_dimensions()
	locked_windows = {}

	for _, win_id in ipairs(vim.api.nvim_list_wins()) do
		local bufnr = vim.api.nvim_win_get_buf(win_id)
		if is_sidebar_buffer(bufnr) then
			locked_windows[win_id] = {
				width = vim.api.nvim_win_get_width(win_id),
				height = vim.api.nvim_win_get_height(win_id),
				bufname = vim.api.nvim_buf_get_name(bufnr),
				filetype = vim.api.nvim_buf_get_option(bufnr, "filetype"),
			}
		end
	end
end

-- Restore dimensions of special windows if they've changed
local function restore_sidebar_dimensions()
	for win_id, dims in pairs(locked_windows) do
		-- Check if window still exists
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
		else
			-- Remove invalid window from tracking
			locked_windows[win_id] = nil
		end
	end
end

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

-- Set up window resize handling
vim.api.nvim_create_autocmd({ "WinResized" }, {
	callback = function()
		restore_sidebar_dimensions()
		-- After restoring, save the new dimensions in case they were legitimately changed
		save_sidebar_dimensions()
	end,
})

-- For older Neovim versions that don't have WinResized
if vim.fn.has("nvim-0.10") == 0 then
	vim.api.nvim_create_autocmd({ "VimResized" }, {
		callback = function()
			restore_sidebar_dimensions()
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
				-- Ignored filetypes (only while resizing)
				ignored_filetypes = ignored_filetypes,
				-- Behavior when cursor is at edge
				at_edge = "stop",
				-- Whether cursor follows swapped buffers
				cursor_follows_swapped_bufs = true,
			})
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
