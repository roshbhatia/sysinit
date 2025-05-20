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
				{ "<leader>a", group = "󱚣 copilot" },
				{ "<leader>b", group = " buffer" },
				{ "<leader>c", group = "󰘧 code" },
				{ "<leader>d", group = " debugger" },
				{ "<leader>e", group = " editor" },
				{ "<leader>f", group = "󰀶 find" },
				{ "<leader>g", group = " git" },
				{ "<leader>j", group = "󱋿 hop" },
				{ "<leader>m", group = " marks" },
				{ "<leader>n", group = "󰎟 notifications" },
				{ "<leader>o", group = "󰉹 outline" },
				{ "<leader>t", group = " terminal" },
			})
		end,
	},
}

return M
