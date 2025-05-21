-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/stevearc/oil.nvim/refs/heads/master/doc/api.md"
local M = {}

M.plugins = {
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			default_file_explorer = true,
			columns = { "icon" },
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
				max_width = 80,
				max_height = 30,
			},
			keymaps = {
				["q"] = { "actions.close", mode = "n" },
			},
		},
		keys = function()
			return {
				{
					"<leader>eb",
					"<cmd>Oil --float<CR>",
					desc = "Editor: Open filesystem in floating buffer",
				},
			}
		end,
	},
}

return M

