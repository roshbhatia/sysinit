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
					"<leader>ag",
					function()
						require("goose.api").toggle()
					end,
					desc = "Toggle chat",
				},
				{
					"<leader>aG",
					function()
						require("goose.api").open_input_new_session()
					end,
					desc = "Create new session",
				},
			}
		end,
	},
}

return M
