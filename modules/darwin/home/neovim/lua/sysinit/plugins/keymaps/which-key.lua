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
			})

			wk.add({
				{ "<leader>a", group = "󱚣 Copilot" },
				{ "<leader>b", group = " Buffer" },
				{ "<leader>c", group = "󰘧 Code" },
				{ "<leader>d", group = " Debugger" },
				{ "<leader>e", group = " Editor" },
				{ "<leader>f", group = "󰀶 Find" },
				{ "<leader>g", group = " Git" },
				{ "<leader>i", group = " Search" },
				{ "<leader>j", group = "󱋿 Hop" },
				{ "<leader>m", group = " Marks" },
				{ "<leader>n", group = "󰎟 Notifications" },
				{ "<leader>t", group = " Terminal" },
			})
		end,
	},
}

return M
