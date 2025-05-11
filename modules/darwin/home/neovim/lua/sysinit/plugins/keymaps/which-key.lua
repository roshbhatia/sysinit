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

			},wk.setup({
				preset = "helix",
			})

			wk.add({
				["<leader>o"] = group = "󰉹 +outline",
				["<leader>t"] = group = " +terminal",
				["<leader>a"] = group = "󱚣 +copilot",
				["<leader>n"] = group = "󰎟 +notifications",
				["<leader>s"] = group = "󰃻 +split",
				["<leader>d"] = group = " +debugger",
				["<leader>g"] = group = " +git",
				["<leader>j"] = group = "󱋿 +hop",
				["<leader>f"] = group = "󰀶 +find",
				["<leader>m"] = group = "󰨁 +map",
				["<leader>e"] = group = " +editor",
				["<leader>x"] = group = "󰁨 +problems",
				["<leader>c"] = group = "󰘧 +code"
			})
		end,
	},
}

return M

