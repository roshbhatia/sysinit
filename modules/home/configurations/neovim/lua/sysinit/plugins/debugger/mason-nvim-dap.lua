local M = {}

M.plugins = {
	{
		"jay-babu/mason-nvim-dap.nvim",
		lazy = false,
		dependencies = {
			"mfussenegger/nvim-dap",
			"williamboman/mason.nvim",
		},
		config = function()
			require("mason-nvim-dap").setup({
				automatic_installation = true,
				handlers = {
					function(config)
						require("mason-nvim-dap").default_setup(config)
					end,
					bash = function(config)
						config.adapters = {
							type = "executable",
							command = vim.fn.stdpath("config") .. "/mason/bin/bash-debug-adapter",
						}
						require("mason-nvim-dap").default_setup(config)
					end,
				},
				ensure_installed = {
					"bash-debug-adapter",
					"delve",
					"python",
				},
			})
		end,
	},
}

return M
