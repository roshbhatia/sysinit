local M = {}

M.plugins = {
	{
		"GeorgesAlkhouri/nvim-aider",
		cmd = "Aider",
		keys = {
			{ "<leader>aa", "<cmd>Aider toggle<cr>", desc = "Copilot: Toggle chat" },
			{ "<leader>as", "<cmd>Aider send<cr>", desc = "Copilot: Send to chat", mode = { "n", "v" } },
			{ "<leader>ac", "<cmd>Aider command<cr>", desc = "Copilot: Chat commands" },
			{ "<leader>ab", "<cmd>Aider buffer<cr>", desc = "Copilot: Send buffer" },
			{ "<leader>ad", "<cmd>Aider add<cr>", desc = "Copilot: Add file" },
			{ "<leader>ar", "<cmd>Aider drop<cr>", desc = "Copilot: Drop file" },
			{ "<leader>aR", "<cmd>Aider reset<cr>", desc = "Copilot: Reset session" },
		},
		dependencies = {
			"folke/snacks.nvim",
			"catppuccin/nvim",
			{
				"nvim-neo-tree/neo-tree.nvim",
				opts = function(_, opts)
					require("nvim_aider.neo_tree").setup(opts)
				end,
			},
		},
		config = function()
			require("nvim_aider").setup({
				aider_cmd = "aider",
				args = {
					"--no-auto-commits",
					"--pretty",
					"--stream",
				},
				auto_reload = true,
				theme = {
					user_input_color = "#a6da95",
					tool_output_color = "#8aadf4",
					tool_error_color = "#ed8796",
					tool_warning_color = "#eed49f",
					assistant_output_color = "#c6a0f6",
					completion_menu_color = "#cad3f5",
					completion_menu_bg_color = "#24273a",
					completion_menu_current_color = "#181926",
					completion_menu_current_bg_color = "#f4dbd6",
				},
				picker_cfg = {
					preset = "vscode",
				},
				-- Other snacks.terminal.Opts options
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
