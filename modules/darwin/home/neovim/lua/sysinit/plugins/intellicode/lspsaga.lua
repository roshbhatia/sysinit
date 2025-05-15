local M = {}

M.plugins = {
	{
		"nvimdev/lspsaga.nvim",
		event = { "LspAttach" },
		config = function()
			require("lspsaga").setup({
				ui = {
					border = "round",
				},
				lightbulb = {
					sign = false,
				},
			})
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"neovim/nvim-lspconfig",
		},
		keys = function()
			return {
				{ "<leader>ca", "<cmd>Lspsaga code_action<CR>", desc = "Code Action" },
				{ "<leader>ca", "<cmd><C-U>Lspsaga code_action<CR>", mode = "v", desc = "Code Action (Range)" },
				{ "<leader>cr", "<cmd>Lspsaga rename<CR>", desc = "Rename" },
				{ "<leader>cd", "<cmd>Lspsaga peek_definition<CR>", desc = "Peek Definition" },
				{ "<leader>cD", "<cmd>Lspsaga goto_definition<CR>", desc = "Go to Definition" },
				{ "<leader>ct", "<cmd>Lspsaga peek_type_definition<CR>", desc = "Peek Type Definition" },
				{ "<leader>ch", "<cmd>Lspsaga hover_doc<CR>", desc = "Hover Documentation" },
				{ "<leader>cf", "<cmd>Lspsaga finder<CR>", desc = "Find References" },
				{ "<leader>co", "<cmd>Lspsaga outline<CR>", desc = "Show Outline" },
				{ "<leader>ci", "<cmd>Lspsaga incoming_calls<CR>", desc = "Incoming Calls" },
				{ "<leader>cu", "<cmd>Lspsaga outgoing_calls<CR>", desc = "Outgoing Calls" },
				{ "<leader>cl", "<cmd>Lspsaga diagnostic_jump_next<CR>", desc = "Next Diagnostic" },
				{ "<leader>cL", "<cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "Previous Diagnostic" },
			}
		end,
	},
}

return M
