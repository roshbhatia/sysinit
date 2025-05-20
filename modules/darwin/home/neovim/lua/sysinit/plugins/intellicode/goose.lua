local M = {}

M.plugins = {
	{
		"azorng/goose.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MeanderingProgrammer/render-markdown.nvim",
		},
		config = function()
			require("goose").setup({
				default_global_keymaps = true, -- If false, disables all default global keymaps
				keymap = {
					global = {
						toggle = "<leader>aa", -- Open goose. Close if opened
						open_input = "<leader>ai", -- Opens and focuses on input window on insert mode
						open_input_new_session = "<leader>aI", -- Opens and focuses on input window on insert mode. Creates a new session
						open_output = "<leader>ao", -- Opens and focuses on output window
						toggle_focus = "<leader>at", -- Toggle focus between goose and last window
						close = "<leader>aq", -- Close UI windows
						toggle_fullscreen = "<leader>af", -- Toggle between normal and fullscreen mode
						select_session = "<leader>as", -- Select and load a goose session
						goose_mode_chat = "<leader>amc", -- Set goose mode to `chat`. (Tool calling disabled. No editor context besides selections)
						goose_mode_auto = "<leader>ama", -- Set goose mode to `auto`. (Default mode with full agent capabilities)
						configure_provider = "<leader>ap", -- Quick provider and model switch from predefined list
						diff_open = "<leader>ad", -- Opens a diff tab of a modified file since the last goose prompt
						diff_next = "<leader>a]", -- Navigate to next file diff
						diff_prev = "<leader>a[", -- Navigate to previous file diff
						diff_close = "<leader>ac", -- Close diff view tab and return to normal editing
						diff_revert_all = "<leader>ara", -- Revert all file changes since the last goose prompt
						diff_revert_this = "<leader>art", -- Revert current file changes since the last goose prompt
					},
				},
			})
		end,
	},
}

return M
