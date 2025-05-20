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
				default_global_keymaps = false, -- Disable global keymaps
			})
		end,
		keys = function()
			return {
				{
					"<leader>aa",
					function()
						require("goose.api").toggle()
					end,
					desc = "AI: Toggle chat",
				},
				{
					"<leader>ai",
					function()
						require("goose.api").open_input()
					end,
					desc = "AI: Open input",
				},
				{
					"<leader>aI",
					function()
						require("goose.api").open_input_new_session()
					end,
					desc = "AI: Create new session",
				},
				{
					"<leader>ao",
					function()
						require("goose.api").open_output()
					end,
					desc = "AI: Open output",
				},
				{
					"<leader>at",
					function()
						require("goose.api").toggle_focus()
					end,
					desc = "AI: Toggle focus",
				},
				{
					"<leader>aq",
					function()
						require("goose.api").close()
					end,
					desc = "AI: Close windows",
				},
				{
					"<leader>af",
					function()
						require("goose.api").toggle_fullscreen()
					end,
					desc = "AI: Fullscreen toggle",
				},
				{
					"<leader>as",
					function()
						require("goose.api").select_session()
					end,
					desc = "AI: Select session",
				},
				{
					"<leader>ap",
					function()
						require("goose.api").configure_provider()
					end,
					desc = "AI: Provider config",
				},
				{
					"<leader>ad",
					function()
						require("goose.api").diff_open()
					end,
					desc = "AI: Diff open",
				},
				{
					"<leader>a]",
					function()
						require("goose.api").diff_next()
					end,
					desc = "AI: Diff next",
				},
				{
					"<leader>a[",
					function()
						require("goose.api").diff_prev()
					end,
					desc = "AI: Diff previous",
				},
				{
					"<leader>ac",
					function()
						require("goose.api").diff_close()
					end,
					desc = "AI: Diff close",
				},
				{
					"<leader>ar",
					function()
						require("goose.api").diff_revert_this()
					end,
					desc = "AI: Revert this file",
				},
				{
					"<leader>aR",
					function()
						require("goose.api").run_new_session("")
					end,
					desc = "AI: Reset chat",
				},
				-- Mode settings
				{ "<leader>am", mode = { "n" }, desc = "+AI Mode" },
				{
					"<leader>amc",
					function()
						require("goose.api").set_mode("chat")
					end,
					desc = "AI: Mode chat",
				},
				{
					"<leader>ama",
					function()
						require("goose.api").set_mode("auto")
					end,
					desc = "AI: Mode auto",
				},
			}
		end,
	},
}

return M
