-- keymaps/init.lua
-- Main keymaps loader that loads and aggregates all keymap groups
local M = {}

-- Define plugins spec for lazy.nvim
M.plugins = {
	{
		"folke/which-key.nvim",
		dependencies = {}
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		opts = {
			preset = "helix"
		},
		keys = {
			{
				"<leader>",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},
}

return M

