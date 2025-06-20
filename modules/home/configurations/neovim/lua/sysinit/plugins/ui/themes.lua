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
					transparent_background = false,
					term_colors = true,
					styles = {
						comments = {
							"italic",
						},
						conditionals = {
							"italic",
						},
						loops = {},
						functions = {},
						keywords = {
							"italic",
						},
						strings = {},
						variables = {},
						numbers = {},
						booleans = {},
						properties = {},
						types = {},
						operators = {},
					},
					integrations = {
						aerial = true,
						alpha = true,
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
		{
			"rose-pine/neovim",
			name = "rose-pine",
			config = function()
				require("rose-pine").setup({
					variant = "main",
					styles = {
						transparency = true,
					},
					highlight_groups = {
						CurSearch = {
							fg = "base",
							bg = "leaf",
							inherit = false,
						},
						NormalOpaque = {
							fg = "subtle",
							bg = "overlay",
						},
						NormalNCOpaque = {
							fg = "subtle",
							bg = "overlay",
						},
						Search = {
							fg = "text",
							bg = "leaf",
							blend = 20,
							inherit = false,
						},
						TelescopeBorder = {
							fg = "overlay",
							bg = "overlay",
						},
						TelescopeNormal = {
							fg = "subtle",
							bg = "overlay",
						},
						TelescopeSelection = {
							fg = "text",
							bg = "highlight_med",
						},
						TelescopeSelectionCaret = {
							fg = "love",
							bg = "highlight_med",
						},
						TelescopeMultiSelection = {
							fg = "text",
							bg = "highlight_high",
						},
						TelescopeTitle = {
							fg = "base",
							bg = "love",
						},
						TelescopePromptTitle = {
							fg = "base",
							bg = "pine",
						},
						TelescopePreviewTitle = {
							fg = "base",
							bg = "iris",
						},
						TelescopePromptNormal = {
							fg = "text",
							bg = "surface",
						},
						TelescopePromptBorder = {
							fg = "surface",
							bg = "surface",
						},
					},
				})
			end,
		},
	},
}

return M

