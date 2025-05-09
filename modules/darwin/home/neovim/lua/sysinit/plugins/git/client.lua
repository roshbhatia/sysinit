local M = {}

M.plugins = {
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			vim.g.lazygit_floating_window_winblend = 0
			vim.g.lazygit_floating_window_scaling_factor = 0.9
			vim.g.lazygit_floating_window_corner_chars = { "╭", "╮", "╰", "╯" }
			vim.g.lazygit_floating_window_use_plenary = 1
			vim.g.lazygit_use_neovim_remote = 0
		end,
		keys = function()
			return {
				{
					"<leader>gg",
					"<cmd>LazyGit<CR>",
					desc = "Git: Open git ui",
				},
				{
					"leader<gh>",
					"<cmd>FloatermNew --name github gh dash<CR>",
					desc = "Git: Open github ui",
				},
			}
		end,
	},
}

return M

