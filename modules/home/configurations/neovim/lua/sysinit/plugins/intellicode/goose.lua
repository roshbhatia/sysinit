local nvim_config = require("sysinit.config.nvim_config").load_config()
local M = {}

M.plugins = {
	{
		"azorng/goose.nvim",
		enabled = nvim_config.copilot.enabled,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MeanderingProgrammer/render-markdown.nvim",
		},
		event = "VeryLazy",
		config = function()
			require("goose").setup({
				providers = nvim_config.goose.providers,
				keymap = {
					global = {
						toggle = "<leader>kk", -- Open goose. Close if opened
						open_input = "<leader>ki", -- Opens and focuses on input window on insert mode
						open_input_new_session = "<leader>kK", -- Opens and focuses on input window on insert mode. Creates a new session
						open_output = "<leader>ko", -- Opens and focuses on output window
						toggle_focus = "<leader>kt", -- Toggle focus between goose and last window
						close = "<leader>kq", -- Close UI windows
						toggle_fullscreen = "<leader>kf", -- Toggle between normal and fullscreen mode
						select_session = "<leader>ks", -- Select and load a goose session
						goose_mode_chat = "<leader>kmc", -- Set goose mode to `chat`. (Tool calling disabled. No editor context besides selections)
						goose_mode_auto = "<leader>kma", -- Set goose mode to `auto`. (Default mode with full agent capabilities)
						configure_provider = "<leader>kp", -- Quick provider and model switch from predefined list
						diff_open = "<leader>kd", -- Opens a diff tab of a modified file since the last goose prompt
						diff_next = "<leader>k]", -- Navigate to next file diff
						diff_prev = "<leader>k[", -- Navigate to previous file diff
						diff_close = "<leader>kc", -- Close diff view tab and return to normal editing
						diff_revert_all = "<leader>kra", -- Revert all file changes since the last goose prompt
						diff_revert_this = "<leader>krt", -- Revert current file changes since the last goose prompt
					},
					window = {
						submit = "<CR>", -- Submit prompt (normal mode)
						submit_insert = "<S-CR>", -- Submit prompt (insert mode)
						close = "<esc>", -- Close UI windows
						stop = "<C-c>", -- Stop goose while it is running
						next_message = "]]", -- Navigate to next message in the conversation
						prev_message = "[[", -- Navigate to previous message in the conversation
						mention_file = "@", -- Pick a file and add to context. See File Mentions section
						toggle_pane = "<tab>", -- Toggle between input and output panes
						prev_prompt_history = "<up>", -- Navigate to previous prompt in history
						next_prompt_history = "<down>", -- Navigate to next prompt in history
					},
				},
				prefered_picker = "telescope",
			})
		end,
	},
}

return M
