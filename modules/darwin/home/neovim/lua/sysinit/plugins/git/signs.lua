local M = {}

M.plugins = {
	{
		"lewis6991/gitsigns.nvim",
		event = { "VeryLazy" },
		config = function()
			require("gitsigns").setup({
				current_line_blame_formatter = "",
			})

			vim.opt.statuscolumn = "%s%=%{v:relnum?v:relnum:v:lnum} "
		end,
		keys = {
			{
				"<leader>ghs",
				function()
					require("gitsigns").stage_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Git: Stage hunk",
			},
			{
				"<leader>ghR",
				function()
					require("gitsigns").reset_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Git: Reset hunk",
			},
			{
				"<leader>gbs",
				function()
					require("gitsigns").stage_buffer()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Git: Stage buffer",
			},
			{
				"<leader>ghu",
				function()
					require("gitsigns").undo_stage_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Git: Unstage hunk",
			},
			{
				"<leader>gbR",
				function()
					require("gitsigns").reset_buffer()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Git: Reset buffer",
			},
			{
				"<leader>ghi",
				function()
					require("gitsigns").preview_hunk_inline()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Git: Preview hunk",
			},
			{
				"<leader>ghn",
				function()
					require("gitsigns").next_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Git: Next hunk",
			},
			{
				"<leader>ghp",
				function()
					require("gitsigns").prev_hunk()
				end,
				mode = "n",
				noremap = true,
				silent = true,
				desc = "Git: Previous hunk",
			},
		},
	},
}

return M

