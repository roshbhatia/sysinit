-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mrjones2014/smart-splits.nvim/refs/heads/master/doc/smart-splits.txt"
local M = {}

M.plugins = {
	{
		"mrjones2014/smart-splits.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("smart-splits").setup({
				-- Ignored buffer types (only while resizing)
				ignored_buftypes = { "nofile", "quickfix", "prompt" },
				-- Ignored filetypes (only while resizing)
				ignored_filetypes = {},
				-- Default resize amount
				default_amount = 3,
				-- Behavior when cursor is at edge
				at_edge = "wrap",
				-- Multiplexer integration (automatically determined unless explicitly set)
				-- Set to "wezterm" to force WezTerm integration
				multiplexer_integration = "wezterm",
				-- Whether cursor follows swapped buffers
				cursor_follows_swapped_bufs = true,
				-- Configure resize mode
				resize_mode = {
					-- Key to exit resize mode
					quit_key = "<ESC>",
					-- Keys for resize directions (h,j,k,l)
					resize_keys = { "h", "j", "k", "l" },
					-- Don't show resize mode notifications
					silent = false,
				},
				-- Log level
				log_level = "info",
			})
		end,
		keys = function()
			return {
				{
					"<C-h>",
					'<cmd>lua require("smart-splits").move_cursor_left()<CR>',
					desc = "Split: Move to left split",
				},
				{
					"<C-j>",
					'<cmd>lua require("smart-splits").move_cursor_down()<CR>',
					desc = "Split: Move to bottom split",
				},
				{
					"<C-k>",
					'<cmd>lua require("smart-splits").move_cursor_up()<CR>',
					desc = "Split: Move to top split",
				},
				{
					"<C-l>",
					'<cmd>lua require("smart-splits").move_cursor_right()<CR>',
					desc = "Split: Move to right split",
				},
				{
					"<M-h>",
					'<cmd>lua require("smart-splits").resize_left()<CR>',
					desc = "Split: Decrease width of current split",
				},
				{
					"<M-j>",
					'<cmd>lua require("smart-splits").resize_down()<CR>',
					desc = "Split: Decrease height of current split",
				},
				{
					"<M-k>",
					'<cmd>lua require("smart-splits").resize_up()<CR>',
					desc = "Split: Increase height of current split",
				},
				{
					"<M-l>",
					'<cmd>lua require("smart-splits").resize_right()<CR>',
					desc = "Split: Increase width of current split",
				},
				{
					"<leader><S-s>",
					"<cmd>split<CR>",
					desc = "Split: Horizontal",
				},
				{
					"<leader><S-v>",
					"<cmd>vsplit<CR>",
					desc = "Split: Vertical",
				},
			}
		end,
	},
}

return M
