local nvim_config = require("sysinit.config.nvim_config").load_config()
local M = {}

M.plugins = {
	{
		enabled = nvim_config.copilot.enabled,
		"giuxtaposition/blink-cmp-copilot",
		dependencies = {
			"zbirenbaum/copilot.lua",
		},
	},
}

return M
