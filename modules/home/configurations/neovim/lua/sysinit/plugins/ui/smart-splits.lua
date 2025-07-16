local M = {}

-- Helper function to check if the current window is a floating "snacks" terminal
local function is_floating_snacks_terminal()
	local win_config = vim.api.nvim_win_get_config(0)
	-- Check if the window is floating and has a "snacks" terminal type
	if win_config.relative ~= "" then
		local buf_name = vim.api.nvim_buf_get_name(0)
		if buf_name:match("snacks") then
			return true
		end
	end
	return false
end

M.plugins = {
	{
		"mrjones2014/smart-splits.nvim",
		lazy = true, -- load only when needed
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
					function()
						smart_splits.move_cursor_left()
					end,
					mode = { "n", "i", "v" },
					desc = "Move to left split",
				},
				{
					"<C-j>",
					function()
						smart_splits.move_cursor_down()
					end,
					mode = { "n", "i", "v" },
					desc = "Move to bottom split",
				},
				{
					"<C-k>",
					function()
						smart_splits.move_cursor_up()
					end,
					mode = { "n", "i", "v" },
					desc = "Move to top split",
				},
				{
					"<C-l>",
					function()
						smart_splits.move_cursor_right()
					end,
					mode = { "n", "i", "v" },
					desc = "Move to right split",
				},
				{
					"<C-S-h>",
					function()
						smart_splits.resize_left()
					end,
					mode = { "n", "i", "v" },
					desc = "Decrease width of current split",
				},
				{
					"<C-S-j>",
					function()
						smart_splits.resize_down()
					end,
					mode = { "n", "i", "v" },
					desc = "Decrease height of current split",
				},
				{
					"<C-S-k>",
					function()
						smart_splits.resize_up()
					end,
					mode = { "n", "i", "v" },
					desc = "Increase height of current split",
				},
				{
					"<C-S-l>",
					function()
						smart_splits.resize_right()
					end,
					mode = { "n", "i", "v" },
					desc = "Increase width of current split",
				},
				{
					"<localleader><s>",
					"<CMD>split<CR>",
					mode = { "n", "t" },
					desc = "Split horizontal",
				},
				{
					"<localleader><v>",
					"<CMD>vsplit<CR>",
					mode = { "n", "t" },
					desc = "Split vertical",
				},
			}
		end,
	},
}

return M

