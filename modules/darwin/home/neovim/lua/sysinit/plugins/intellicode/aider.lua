local M = {}

M.plugins = {
	{
		enabled = false,
		"GeorgesAlkhouri/nvim-aider",
		cmd = "BufEnter",
		keys = {
			{ "<leader>aa", "<cmd>Aider toggle<cr>", desc = "Copilot: Toggle chat" },
			{ "<leader>as", "<cmd>Aider send<cr>", desc = "Copilot: Send to chat", mode = { "n", "v" } },
			{ "<leader>ai", "<cmd>Aider command<cr>", desc = "Copilot: Chat commands" },
			{ "<leader>ab", "<cmd>Aider buffer<cr>", desc = "Copilot: Send buffer" },
			{ "<leader>ad", "<cmd>Aider add<cr>", desc = "Copilot: Add file" },
			{ "<leader>ar", "<cmd>Aider drop<cr>", desc = "Copilot: Drop file" },
			{ "<leader>aR", "<cmd>Aider reset<cr>", desc = "Copilot: Reset session" },
			{ "<leader>aa", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "neo-tree" },
			{ "<leader>ad", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "neo-tree" },
		},
		dependencies = {
			"folke/snacks.nvim",
			"catppuccin/nvim",
			"zbirenbaum/copilot.lua",
		},
		config = function()
			require("nvim_aider").setup({
				aider_cmd = "aider",
				args = {
					"-c",
					"~/.aider.nvim.copilot.conf.yml",
					"--model-settings-file ~/.aider.nvim.copilot.model.settings.yml",
					"--openai-api-key $(get-copilot-token)",
				},
				auto_reload = true,
				picker_cfg = {
					preset = "telescope",
				},
				config = {
					os = { editPreset = "nvim-remote" },
					gui = { nerdFontsVersion = "3" },
				},
				win = {
					wo = { winbar = "Aider" },
					style = "nvim_aider",
					position = "right",
				},
			})
		end,
	},
}
return M
