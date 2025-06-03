local M = {}

M.plugins = {
	{
		"nvimdev/lspsaga.nvim",
		event = { "LspAttach" },
		config = function()
			require("lspsaga").setup({
				symbol_in_winbar = {
					enable = false,
				},
				lightbulb = {
					virtual_text = false,
				},
				ui = {
					code_action = "󰺕",
					actionfix = "",
				},
				hover = {
					max_width = 1.2,
					max_height = 1,
				},
				implement = {
					enable = true,
				},
				rename = {
					auto_save = true,
				},
				code_action = {
					show_server_name = true,
					max_height = 0.6,
				},
				diagnostic = {
					auto_preview = true,
				},
			})
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"neovim/nvim-lspconfig",
			"nvimtools/none-ls.nvim",
		},
		keys = function()
			return {
				{ "<leader>ca", "<cmd>Lspsaga code_action<CR>", desc = "Code Action" },
				{ "<leader>ca", "<cmd><C-U>Lspsaga code_action<CR>", mode = "v", desc = "Code Action (Range)" },
				{ "<leader>cr", "<cmd>Lspsaga rename<CR>", desc = "Rename" },
				{ "<leader>cd", "<cmd>Lspsaga peek_definition<CR>", desc = "Peek Definition" },
				{ "<leader>cD", "<cmd>Lspsaga goto_definition<CR>", desc = "Go to Definition" },
				{ "<leader>ch", "<cmd>Lspsaga hover_doc<CR>", desc = "Hover Documentation" },
				{ "<leader>cn", "<cmd>Lspsaga diagnostic_jump_next<CR>", desc = "Next Diagnostic" },
				{ "<leader>cp", "<cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "Previous Diagnostic" },
			}
		end,
	},
}

return M
