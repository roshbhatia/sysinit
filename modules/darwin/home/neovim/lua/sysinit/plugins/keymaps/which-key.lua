local M = {}

M.plugins = {
	{
		"folke/which-key.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		opts = {
			preset = "helix",
			defaults = {
				["<leader>o"] = { group = "󰉹 +outline" },
				["<leader>t"] = { group = " +terminal" },
				["<leader>a"] = { group = "󱚣 +copilot" },
				["<leader>n"] = { group = "󰎟 +notifications" },
				["<leader>s"] = { group = "󰃻 +split" },
				["<leader>d"] = { group = " +debugger" },
				["<leader>g"] = { group = " +git" },
				["<leader>j"] = { group = "󱋿 +hop" },
				["<leader>f"] = { group = "󰀶 +find" },
				["<leader>m"] = { group = "󰨁 +map" },
				["<leader>e"] = { group = " +editor" },
				["<leader>x"] = { group = "󰁨 +problems" },
				["<leader>c"] = { group = "󰘧 +code" },
			},
		},
	},
}

return M

