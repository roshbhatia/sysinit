local M = {}

M.plugins = {
	{
		"metalelf0/black-metal-theme-neovim",
		lazy = false,
		priority = 1000,
		config = function()
			require("black-metal").setup({
				theme = "burzum",
				alt_bg = false,
				favor_treesitter_hl = false,
				plain_float = false,
				show_eob = false,
				transparent = true,

				-- The following options allow for more control over some plugin appearances.
				plugin = {
					cmp = { -- works for nvim.cmp and blink.nvim
						-- Don't highlight lsp-kind items. Only the current selection will be highlighted.
						plain = false,
						-- Reverse lsp-kind items' highlights in blink/cmp menu.
						reverse = false,
					},
				},
			})
			require("black-metal").load()
		end,
	},
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
