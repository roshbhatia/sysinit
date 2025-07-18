local M = {}

M.plugins = {
	{
		"lewis6991/gitsigns.nvim",
		lazy = true,
		config = function()
			require("gitsigns").setup({
				current_line_blame_formatter = "",
			})
		end,
		keys = {
			{
				"<localleader>ghs",
				function()
					require("gitsigns").stage_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Stage hunk",
			},
			{
				"<localleader>ghR",
				function()
					require("gitsigns").reset_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Reset hunk",
			},
			{
				"<localleader>gbs",
				function()
					require("gitsigns").stage_buffer()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Stage buffer",
			},
			{
				"<localleader>ghu",
				function()
					require("gitsigns").undo_stage_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Unstage hunk",
			},
			{
				"<localleader>gbR",
				function()
					require("gitsigns").reset_buffer()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Reset buffer",
			},
			{
				"<localleader>ghi",
				function()
					require("gitsigns").preview_hunk_inline()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Preview hunk",
			},
			{
				"<localleader>ghn",
				function()
					require("gitsigns").next_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Next hunk",
			},
			{
				"<localleader>ghN",
				function()
					require("gitsigns").prev_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Previous hunk",
			},
			{
				"<RightMouse>",
				function()
					local mouse_pos = vim.fn.getmousepos()
					if mouse_pos.column <= 2 then
						vim.api.nvim_win_set_cursor(0, { mouse_pos.line, 0 })
						require("gitsigns").preview_hunk_inline()
					end
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Toggle inline preview",
			},
		},
	},
}

return M

