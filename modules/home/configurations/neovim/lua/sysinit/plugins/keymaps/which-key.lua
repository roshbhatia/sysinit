local nvim_config = require("sysinit.config.nvim_config").load_config()
local M = {}

M.plugins = {
	{
		"folke/which-key.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		lazy = false,
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
					"<localleader>b",
					group = "Buffer Actions",
				},
				{
					"<localleader>e",
					group = "Editor Actions",
				},
				{
					"<localleader>p",
					group = "Snacks/Profiler",
				},
				{
					"<localleader>r",
					group = "Refresh",
				},
				{
					"<leader>j",
					group = "Goose",
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
					"<localleader>d",
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

			if nvim_config.copilot.enabled then
				wk.add({
					{
						"<leader>h",
						group = "Copilot - Avante",
					},
					{
						"<leader>j",
						group = "Copilot - Goose",
					},
					{
						"<leader>k",
						group = "Copilot - Code Companion",
					},
				})
			end

			if vim.env.SYSINIT_DEBUG == "1" then
				wk.add({
					{
						"<localleader>p",
						group = "Profiler",
					},
				})
			end
		end,
	},
}

return M

