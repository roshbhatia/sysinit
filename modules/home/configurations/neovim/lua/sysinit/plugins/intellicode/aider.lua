local M = {}

M.plugins = {
	{
		enabled = false 
		"GeorgesAlkhouri/nvim-aider",
		cmd = "Aider",
		keys = {
			{ "<leader>Aa", "<cmd>Aider toggle<cr>", desc = "Toggle Aider" },
			{ "<leader>AA", "<cmd>Aider reset<cr>", desc = "New Aider Session" },
		},
		opts = {
			auto_reload = true,
			picker_cfg = {
				preset = "telescope",
			},
			config = {
				start_insert = false,
				auto_insert = false,
				auto_close = true,
			},
		},
		config = function(_, opts)
			local aider = require("nvim_aider")
			local api = aider.api

			aider.setup(opts)

			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
				callback = function()
					if vim.fn.expand("%") ~= "" then
						api.add_current_file()
					end
				end,
			})

			vim.api.nvim_create_autocmd("DiagnosticChanged", {
				callback = function()
					api.send_diagnostics_with_prompt({ prompt = "Diagnostics update:" })
				end,
			})
		end,
	},
}

return M

