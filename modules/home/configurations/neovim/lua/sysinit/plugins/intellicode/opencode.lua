local M = {}

M.plugins = {
	{
		"NickvanDyke/opencode.nvim",
		dependencies = {
			"folke/snacks.nvim",
		},
		opts = function()
			return {
				auto_reload = true,
				auto_focus = false,
				command = "opencode",
				context = {
					["@file"] = require("opencode.context").file,
					["@files"] = require("opencode.context").files,
					["@cursor"] = require("opencode.context").cursor_position,
					["@selection"] = require("opencode.context").visual_selection,
					["@diagnostics"] = require("opencode.context").diagnostics,
					["@quickfix"] = require("opencode.context").quickfix,
					["@diff"] = require("opencode.context").git_diff,
				},
				win = {
					position = "right",
				},
			}
		end,
		keys = {
			{
				"<leader>jj",
				function()
					require("snacks.terminal").toggle("opencode", {
						win = {
							position = "right",
							title = "",
							title_pos = "center",
						},
					})
				end,
				desc = "Toggle opencode",
			},
			{
				"<leader>ja",
				function()
					require("opencode").ask()
				end,
				desc = "Ask opencode",
				mode = { "n", "v" },
			},
			{
				"<leader>jA",
				function()
					require("opencode").ask("@file ")
				end,
				desc = "Ask opencode about current file",
				mode = { "n", "v" },
			},
			{
				"<leader>jJ",
				function()
					require("opencode").command("/new")
				end,
				desc = "New session",
			},
			{
				"<leader>je",
				function()
					require("opencode").prompt("Explain @cursor and its context")
				end,
				desc = "Explain code near cursor",
			},
			{
				"<leader>jr",
				function()
					require("opencode").prompt("Review @file for correctness and readability")
				end,
				desc = "Review file",
			},
			{
				"<leader>jf",
				function()
					require("opencode").prompt("Fix these @diagnostics")
				end,
				desc = "Fix errors",
			},
			{
				"<leader>jo",
				function()
					require("opencode").prompt("Optimize @selection for performance and readability")
				end,
				desc = "Optimize selection",
				mode = "v",
			},
			{
				"<leader>jd",
				function()
					require("opencode").prompt("Add documentation comments for @selection")
				end,
				desc = "Document selection",
				mode = "v",
			},
			{
				"<leader>jt",
				function()
					require("opencode").prompt("Add tests for @selection")
				end,
				desc = "Test selection",
				mode = "v",
			},
		},
	},
}

return M
