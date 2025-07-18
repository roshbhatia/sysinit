local M = {}

M.plugins = {
	{
		"sudo-tee/opencode.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("opencode").setup({
				prefered_picker = "telescope",
				default_global_keymaps = false, -- We'll set our own keymaps
				default_mode = "build",
				keymap = {
					global = {
						toggle = "<leader>ll",
						open_input = "<leader>li",
						open_input_new_session = "<leader>lI",
						open_output = "<leader>lo",
						toggle_focus = "<leader>lt",
						close = "<leader>lq",
						toggle_fullscreen = "<leader>lf",
						select_session = "<leader>ls",
						configure_provider = "<leader>lp",
						diff_open = "<leader>ld",
						diff_next = "<leader>l]",
						diff_prev = "<leader>l[",
						diff_close = "<leader>lc",
						diff_revert_all = "<leader>lra",
						diff_revert_this = "<leader>lrt",
						open_configuration_file = "<leader>lC",
					},
				},
				ui = {
					floating = false,
					window_width = 0.40,
					input_height = 0.15,
					fullscreen = false,
					layout = "right",
					display_model = true,
				},
				context = {
					cursor_data = true,
					diagnostics = {
						info = false,
						warn = true,
						error = true,
					},
				},
				debug = {
					enabled = false,
				},
			})
		end,
		keys = {
			{
				"<leader>ll",
				function()
					require("opencode.api").toggle()
				end,
				desc = "Toggle opencode",
			},
			{
				"<leader>li",
				function()
					require("opencode.api").open_input()
				end,
				desc = "Open input window",
			},
			{
				"<leader>lI",
				function()
					require("opencode.api").open_input_new_session()
				end,
				desc = "Open input window (new session)",
			},
			{
				"<leader>lo",
				function()
					require("opencode.api").open_output()
				end,
				desc = "Open output window",
			},
			{
				"<leader>lt",
				function()
					require("opencode.api").toggle_focus()
				end,
				desc = "Toggle focus opencode/editor",
			},
			{
				"<leader>lq",
				function()
					require("opencode.api").close()
				end,
				desc = "Close opencode windows",
			},
			{
				"<leader>lf",
				function()
					require("opencode.api").toggle_fullscreen()
				end,
				desc = "Toggle fullscreen mode",
			},
			{
				"<leader>ls",
				function()
					require("opencode.api").select_session()
				end,
				desc = "Select session",
			},
			{
				"<leader>lp",
				function()
					require("opencode.api").configure_provider()
				end,
				desc = "Configure provider",
			},
			{
				"<leader>ld",
				function()
					require("opencode.api").diff_open()
				end,
				desc = "Open diff view",
			},
			{
				"<leader>l]",
				function()
					require("opencode.api").diff_next()
				end,
				desc = "Next file diff",
			},
			{
				"<leader>l[",
				function()
					require("opencode.api").diff_prev()
				end,
				desc = "Previous file diff",
			},
			{
				"<leader>lc",
				function()
					require("opencode.api").diff_close()
				end,
				desc = "Close diff view",
			},
			{
				"<leader>lra",
				function()
					require("opencode.api").diff_revert_all()
				end,
				desc = "Revert all changes",
			},
			{
				"<leader>lrt",
				function()
					require("opencode.api").diff_revert_this()
				end,
				desc = "Revert current file",
			},
			{
				"<leader>lC",
				function()
					require("opencode.api").open_configuration_file()
				end,
				desc = "Open config file",
			},
		},
	},
}

return M

