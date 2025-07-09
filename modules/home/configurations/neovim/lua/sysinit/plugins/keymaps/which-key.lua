local M = {}

M.plugins = {
	{
		"folke/which-key.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")

			wk.setup({
				preset = "helix",
				icons = {
					mappings = false,
				},
				notify = false,
			})

			wk.add({
				{
					"<leader>a",
					group = "Copilot - Avante",
				},
				{
					"<leader>b",
					group = "Buffer",
				},
				{
					"<leader>c",
					group = "Code",
				},
				{
					"<localleader>c",
					group = "Code",
				},
				{
					"<leader>d",
					group = "Debugger",
				},
				{
					"<leader>e",
					group = "Editor",
				},
				{
					"<leader>f",
					group = "Find",
				},
				{
					"<leader>g",
					group = "Git",
				},
				{
					"<leader>gb",
					group = "Buffer",
				},
				{
					"<leader>gh",
					group = "Hunk",
				},
				{
					"<leader>gr",
					group = "Github Review",
				},
				{
					"<leader>h",
					group = "Copilot - Goose",
				},
				{
					"<leader>i",
					group = "Search",
				},
				{
					"<localleader>.",
					group = "Cursor",
				},
				{
					"<leader>m",
					group = "Marks",
				},
				{
					"<leader>n",
					group = "Notifications",
				},
				{
					"<leader>r",
					group = "Refresh",
				},
			})
		end,
	},
}

return M
