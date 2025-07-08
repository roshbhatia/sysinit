local M = {}

M.plugins = {
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"folke/snacks.nvim",
		},
		config = function()
			require("oil").setup({
				default_file_explorer = true,
				columns = {
					"icon",
				},
				delete_to_trash = true,
				skip_confirm_for_simple_edits = true,
				watch_for_changes = true,
				git = {
					add = function(path)
						return true
					end,
					mv = function(src_path, dest_path)
						return true
					end,
					rm = function(path)
						return true
					end,
				},
				view_options = {
					show_hidden = true,
					is_hidden_file = function(name)
						return vim.startswith(name, ".")
					end,
				},
				float = {
					border = "rounded",
				},
				keymaps = {
					["q"] = { "actions.close", mode = "n" },
					["<C-v>"] = { "actions.select", opts = { vertical = true } },
					["<C-s>"] = { "actions.select", opts = { horizontal = true } },
				},
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "OilActionsPost",
				callback = function(event)
					if event.data.actions.type == "move" then
						Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
					end
				end,
			})
		end,
		keys = function()
			return {
				{
					"<leader>ee",
					"<CMD>Oil --float --preview<CR>",
					desc = "Open filesystem buffer",
				},
			}
		end,
	},
}

return M
