local M = {}

M.plugins = {
	{
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
		},
		config = function(_, opts)
			require("nvim_aider").setup(opts)
		end,
	},
}

return M
