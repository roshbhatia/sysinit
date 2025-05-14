local M = {}

M.plugins = {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			vim.g.neo_tree_remove_legacy_commands = 1

			require("neo-tree").setup({
				auto_clean_after_session_restore = true,
				close_if_last_window = true,
				sort_case_insensitive = true,
				window = {
					width = 55,
					auto_expand_width = true,
				},
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
				},
			})

			-- File explorer: toggle Neotree (Alt+b)
			vim.keymap.set("n", "<A-b>", "<cmd>Neotree toggle<CR>", {
				noremap = true,
				silent = true,
				desc = "Editor: Toggle file tree",
			})
		end,
		keys = {
			{
				"<leader>ee",
				function()
					vim.cmd("Neotree toggle")
					vim.cmd("wincmd p")
				end,
				desc = "Editor: Toggle file tree",
			},
		},
	},
}

return M
