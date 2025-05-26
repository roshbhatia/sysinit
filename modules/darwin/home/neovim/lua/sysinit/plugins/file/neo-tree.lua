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
			"folke/snacks.nvim",
		},
		config = function()
			vim.g.neo_tree_remove_legacy_commands = 1

			require("neo-tree").setup({
				event_handlers = {
					{
						event = "neo_tree_buffer_enter",
						handler = function(arg)
							vim.opt_local.number = false
							vim.opt_local.relativenumber = false
						end,
					},
				},
				close_if_last_window = true,
				enable_diagnostics = true,
				sort_case_insensitive = true,
				default_component_configs = {
					indent = {
						with_expanders = true,
					},
					icon = {
						folder_closed = "",
						folder_open = "",
					},
					name = {
						use_git_status_colors = true,
					},
					git_status = {
						symbols = {
							added = "",
							deleted = "",
							modified = "",
							renamed = "",
							untracked = "",
							ignored = "",
							unstaged = "",
							staged = "",
							conflict = "",
						},
					},
				},
				window = {
					mappings = {
						["<2-LeftMouse>"] = "open",
						["<cr>"] = "open",
						["<esc>"] = "revert_preview",
						["P"] = {
							"toggle_preview",
							config = {
								use_float = true,
							},
						},
						["s"] = "open_split",
						["v"] = "open_vsplit",
						["w"] = "open_with_window_picker",
						["z"] = "close_all_nodes",
						["Z"] = "expand_all_nodes",
						["a"] = {
							"add",
							config = {
								show_path = "none",
							},
						},
						["d"] = "delete",
						["r"] = "rename",
						["y"] = "copy_to_clipboard",
						["x"] = "cut_to_clipboard",
						["p"] = "paste_from_clipboard",
						["c"] = "copy",
						["m"] = "move",
						["q"] = "close_window",
						["?"] = "show_help",
						["<"] = "prev_source",
						[">"] = "next_source",
					},
				},
				filesystem = {
					filtered_items = {
						hide_dotfiles = false,
						hide_gitignored = false,
						hide_by_name = {
							".DS_Store",
							"node_modules",
							".git",
							".goose",
						},
						hide_by_pattern = { "*.meta", "*.aider*" },
						never_show = { ".DS_Store" },
					},
					follow_current_file = {
						enabled = true,
					},
					use_libuv_file_watcher = true,
					event_handlers = function()
						local function on_move(data)
							Snacks.rename.on_rename_file(data.source, data.destination)
						end
						return {
							{
								event = require("neo-tree.events").FILE_MOVED,
								handler = on_move,
							},
							{
								event = require("neo-tree.events").FILE_RENAMED,
								handler = on_move,
							},
						}
					end,
				},
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
