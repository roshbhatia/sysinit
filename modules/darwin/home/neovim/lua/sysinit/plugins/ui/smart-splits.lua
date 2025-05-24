-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mrjones2014/smart-splits.nvim/refs/heads/master/doc/smart-splits.txt"
local M = {}

-- Helper function to create movement keybindings with floating window check
local function create_movement_keybinding(direction, func)
	return function()
		local win_config = vim.api.nvim_win_get_config(0)
		if win_config.relative == "" then -- Only allow movement if not in a floating window
			func()
		end
	end
end

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
		end,
		keys = function()
			local smart_splits = require("smart-splits")
			return {
				{
					"<C-h>",
					create_movement_keybinding("left", smart_splits.move_cursor_left),
					mode = { "n", "i", "v", "t" },
					desc = "Move to left split",
				},
				{
					"<C-j>",
					create_movement_keybinding("down", smart_splits.move_cursor_down),
					mode = { "n", "i", "v", "t" },
					desc = "Move to bottom split",
				},
				{
					"<C-k>",
					create_movement_keybinding("up", smart_splits.move_cursor_up),
					mode = { "n", "i", "v", "t" },
					desc = "Move to top split",
				},
				{
					"<C-l>",
					create_movement_keybinding("right", smart_splits.move_cursor_right),
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
