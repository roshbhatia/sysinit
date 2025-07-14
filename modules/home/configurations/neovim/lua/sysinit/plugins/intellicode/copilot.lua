local nvim_config = require("sysinit.config.nvim_config").load_config()
local M = {}

M.plugins = {
	{
		enabled = nvim_config.copilot.enabled,
		"zbirenbaum/copilot.lua",
		event = "Verylazy",
		config = function()
			require("copilot").setup({
				panel = {
					auto_refresh = false,
				},
				suggestion = {
					enabled = false,
					auto_trigger = false,
				},
			})
		end,
	},
}

return M

