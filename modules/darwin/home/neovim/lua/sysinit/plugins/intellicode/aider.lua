local M = {}

M.plugins = {
	{
		"GeorgesAlkhouri/nvim-aider",
		cmd = "Aider",
		keys = {
			{ "<leader>aa", "<cmd>Aider toggle<cr>", desc = "Toggle Aider" },
			{ "<leader>as", "<cmd>Aider send<cr>", desc = "Send to Aider", mode = { "n", "v" } },
			{ "<leader>ac", "<cmd>Aider command<cr>", desc = "Aider Commands" },
			{ "<leader>ab", "<cmd>Aider buffer<cr>", desc = "Send Buffer" },
			{ "<leader>ad", "<cmd>Aider add<cr>", desc = "Add File" },
			{ "<leader>ar", "<cmd>Aider drop<cr>", desc = "Drop File" },
			{ "<leader>an", "<cmd>Aider reset<cr>", desc = "Reset Session" },
		},
		dependencies = {
			"folke/snacks.nvim",
		},
		config = function()
			vim.o.autoread = true

			require("nvim_aider").setup({
				aider_cmd = "aider",
				args = {
					"-c ~/.aider.nvim.copilot.conf.yml",
				},
				auto_reload = false,
				picker_cfg = {
					preset = "telescope",
				},
			})
		end,
	},
}

return M
