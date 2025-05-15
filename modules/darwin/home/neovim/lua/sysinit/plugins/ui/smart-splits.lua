-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mrjones2014/smart-splits.nvim/refs/heads/master/doc/smart-splits.txt"
local M = {}

M.plugins = {
	{
		"mrjones2014/smart-splits.nvim",
		commit = "f011745141fbe767183dfe3d057e8ac039082c9b",
		lazy = false,
		config = function()
			require("smart-splits").setup({
				ignored_buftypes = {
					"terminal",
					"quickfix",
					"prompt",
					"nofile",
					"neotree",
					"NeoTree",
					"Neotree",
					"neo-tree",
					"Avante",
					"AvanteSelectedFiles",
					"AvanteInput",
					"AvantePromptInput",
				},
				-- Ignored filetypes (only while resizing)
				ignored_filetypes = {
					"",
					"NvimTree",
					"neotree",
					"NeoTree",
					"Neotree",
					"neo-tree",
					"neo-tree.nvim",
					"Avante",
					"AvanteSelectedFiles",
					"AvanteInput",
					"AvantePromptInput",
				},
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
					desc = "Move to left split",
				},
				{
					"<C-j>",
					'<cmd>lua require("smart-splits").move_cursor_down()<CR>',
					desc = "Move to bottom split",
				},
				{
					"<C-k>",
					'<cmd>lua require("smart-splits").move_cursor_up()<CR>',
					desc = "Move to top split",
				},
				{
					"<C-l>",
					'<cmd>lua require("smart-splits").move_cursor_right()<CR>',
					desc = "Move to right split",
				},
				{
					"<M-h>",
					'<cmd>lua require("smart-splits").resize_left()<CR>',
					desc = "Decrease width of current split",
				},
				{
					"<M-j>",
					'<cmd>lua require("smart-splits").resize_down()<CR>',
					desc = "Decrease height of current split",
				},
				{
					"<M-k>",
					'<cmd>lua require("smart-splits").resize_up()<CR>',
					desc = "Increase height of current split",
				},
				{
					"<M-l>",
					'<cmd>lua require("smart-splits").resize_right()<CR>',
					desc = "Increase width of current split",
				},
				{
					"<leader><S-s>",
					"<cmd>split<CR>",
					desc = "󰃻 Horizontal",
				},
				{
					"<leader><S-v>",
					"<cmd>vsplit<CR>",
					desc = "󰃻 Vertical",
				},
			}
		end,
	},
}

return M
