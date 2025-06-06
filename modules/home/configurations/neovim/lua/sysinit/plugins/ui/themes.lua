local M = {}

M.plugins = {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		config = function()
			require("catppuccin").setup({
				flavour = "frappe",
				show_end_of_buffer = false,
				transparent_background = true,
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
		"EdenEast/nightfox.nvim",
		config = function()
			require("nightfox").setup({
				transparent = true,
				terminal_colors = true,
				dim_inactive = true,
			})
		end,
	},
	{
		"rebelot/kanagawa.nvim",
		config = function()
			require("kanagawa").setup({
				compile = false,
				undercurl = true,
				commentStyle = { italic = true },
				functionStyle = {},
				keywordStyle = { italic = true },
				statementStyle = { bold = true },
				typeStyle = {},
				transparent = true,
				dimInactive = false,
				terminalColors = true,
				theme = "wave",
				background = {
					dark = "wave",
					light = "lotus",
				},
			})
		end,
	},
}

return M
