local M = {}

M.plugins = {
	{
		{
			"catppuccin/nvim",
			name = "catppuccin",
			config = function()
				require("catppuccin").setup({
					flavour = "frappe",
					show_end_of_buffer = false,
					term_colors = true,
					integrations = {
						aerial = true,
						alpha = true,
						avante = true,
						cmp = true,
						copilot_vim = true,
						dap = true,
						dap_ui = true,
						dropbar = {
							enabled = true,
						},
						fzf = true,
						gitsigns = true,
						grug_far = true,
						hop = true,
						lsp_trouble = true,
						mason = true,
						native_lsp = {
							enabled = true,
						},
						neotree = true,
						noice = true,
						render_markdown = true,
						snacks = {
							enabled = true,
						},
						telescope = {
							enabled = true,
						},
						treesitter = true,
						treesitter_context = true,
						which_key = true,
						window_picker = true,
					},
				})

				vim.cmd("colorscheme catppuccin")
			end,
		},
	},
}

return M

