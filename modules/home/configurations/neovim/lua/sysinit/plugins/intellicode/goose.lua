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
				default_global_keymaps = false, -- Disable global keymaps
				github_copilot = {
					"github_copilot/gpt-4o",
					"github_copilot/o1",
					"github_copilot/o3-mini",
					"github_copilot/claude-3.5-sonnet",
					"github_copilot/claude-3.7-sonnet",
					"github_copilot/claude-3.7-sonnet-thought",
					"github_copilot/gemini-2.0-flash-001",
				},
				ui = {
					type = "split",
				},
			})
		end,
		keys = function()
			return {
				{
					"<leader>aa",
					function()
						require("goose.api").toggle()
					end,
					desc = "Toggle chat",
				},
				{
					"<leader>aA",
					function()
						require("goose.api").open_input_new_session()
					end,
					desc = "Create new session",
				},
				{
					"<leader>at",
					function()
						require("goose.api").toggle_focus()
					end,
					desc = "Toggle focus",
				},
				{
					"<leader>aq",
					function()
						require("goose.api").close()
					end,
					desc = "Close windows",
				},
				{
					"<leader>af",
					function()
						require("goose.api").toggle_fullscreen()
					end,
					desc = "Fullscreen toggle",
				},
				{
					"<leader>as",
					function()
						require("goose.api").select_session()
					end,
					desc = "Select session",
				},
				{
					"<leader>ap",
					function()
						require("goose.api").configure_provider()
					end,
					desc = "Provider config",
				},
				{
					"<leader>ad",
					function()
						require("goose.api").diff_open()
					end,
					desc = "Diff open",
				},
				{
					"<leader>an",
					function()
						require("goose.api").diff_next()
					end,
					desc = "Diff next",
				},
				{
					"<leader>ap",
					function()
						require("goose.api").diff_prev()
					end,
					desc = "Diff previous",
				},
				{
					"<leader>ac",
					function()
						require("goose.api").diff_close()
					end,
					desc = "Diff close",
				},
				{
					"<leader>aU",
					function()
						require("goose.api").diff_revert_this()
					end,
					desc = "Revert this file",
				},
				{
					"<leader>aR",
					function()
						require("goose.api").run_new_session("")
					end,
					desc = "Reset chat",
				},
			}
		end,
	},
}

return M

