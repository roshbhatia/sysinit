local M = {}

M.plugins = {
	{
		"azorng/goose.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MeanderingProgrammer/render-markdown.nvim",
		},
		event = "VeryLazy",
		config = function()
			require("goose").setup({
				github_copilot = {
					"github_copilot/gemini-2.0-flash-001",
					"github_copilot/gpt-4.1",
					"github_copilot/claude-3.7-sonnet",
					"github_copilot/claude-3.5-sonnet",
				},
				keymap = {
					global = {
						toggle = "<leader>hh", -- Open goose. Close if opened
						open_input = "<leader>hi", -- Opens and focuses on input window on insert mode
						open_input_new_session = "<leader>hH", -- Opens and focuses on input window on insert mode. Creates a new session
						open_output = "<leader>ho", -- Opens and focuses on output window
						toggle_focus = "<leader>ht", -- Toggle focus between goose and last window
						close = "<leader>hq", -- Close UI windows
						toggle_fullscreen = "<leader>hf", -- Toggle between normal and fullscreen mode
						select_session = "<leader>hs", -- Select and load a goose session
						goose_mode_chat = "<leader>hmc", -- Set goose mode to `chat`. (Tool calling disabled. No editor context besides selections)
						goose_mode_auto = "<leader>hma", -- Set goose mode to `auto`. (Default mode with full agent capabilities)
						configure_provider = "<leader>hp", -- Quick provider and model switch from predefined list
						diff_open = "<leader>hd", -- Opens a diff tab of a modified file since the last goose prompt
						diff_next = "<leader>h]", -- Navigate to next file diff
						diff_prev = "<leader>h[", -- Navigate to previous file diff
						diff_close = "<leader>hc", -- Close diff view tab and return to normal editing
						diff_revert_all = "<leader>hra", -- Revert all file changes since the last goose prompt
						diff_revert_this = "<leader>hrt", -- Revert current file changes since the last goose prompt
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
