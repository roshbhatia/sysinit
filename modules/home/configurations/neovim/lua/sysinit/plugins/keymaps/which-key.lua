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
			})

			wk.add({
				{
					"<leader>a",
					group = "Copilot",
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
					"<leader>i",
					group = "Search",
				},
				{
					"<leader>.",
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
				{
					"<leader>t",
					group = "Terminal",
				},
			})
		end,
	},
}

return M
