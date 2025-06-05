local M = {}

M.plugins = {
	{
		"zaldih/themery.nvim",
		lazy = false,
		priority = 2500,
		dependencies = {
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
							comments = { "italic" },
							conditionals = { "italic" },
							loops = {},
							functions = {},
							keywords = { "italic" },
							strings = {},
							variables = {},
							numbers = {},
							booleans = {},
							properties = {},
							types = {},
							operators = {},
						},
						integrations = {
							alpha = true,
							aerial = true,
							cmp = true,
							gitsigns = true,
							grug_far = true,
							mason = true,
							neotree = true,
							copilot_vim = true,
							dap = true,
							dap_ui = true,
							dropbar = { enabled = true },
							fzf = true,
							hop = true,
							native_lsp = { enabled = true },
							nvim_notify = false,
							render_markdown = true,
							snacks = { enabled = true },
							telescope = { enabled = true },
							treesitter = true,
							lsp_trouble = true,
							which_key = true,
						},
					})
				end,
			},
			{
				"EdenEast/nightfox.nvim",
				config = function()
					require("nightfox").setup({
						compile_path = vim.fn.stdpath("cache") .. "/nightfox",
						compile_file_suffix = "_compiled",
						transparent = true,
						terminal_colors = true,
						dim_inactive = false,
						module_default = true,
						styles = {
							comments = "italic",
							conditionals = "NONE",
							constants = "NONE",
							functions = "NONE",
							keywords = "italic",
							numbers = "NONE",
							operators = "NONE",
							strings = "NONE",
							types = "NONE",
							variables = "NONE",
						},
						inverse = {
							match_paren = false,
							visual = false,
							search = false,
						},
					})
				end,
			},
			{
				"folke/tokyonight.nvim",
				config = function()
					require("tokyonight").setup({
						style = "moon",
						transparent = true,
						terminal_colors = true,
						styles = {
							comments = { italic = true },
							keywords = { italic = true },
							functions = {},
							variables = {},
							sidebars = "transparent",
							floats = "transparent",
						},
						dim_inactive = false,
						cache = true,
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
			{
				"navarasu/onedark.nvim",
				config = function()
					require("onedark").setup({
						style = "deep",
						transparent = true,
						term_colors = true,
						ending_tildes = false,
						cmp_itemkind_reverse = false,
						code_style = {
							comments = "italic",
							keywords = "none",
							functions = "none",
							strings = "none",
							variables = "none",
						},
						lualine = { transparent = true },
						diagnostics = {
							darker = true,
							undercurl = true,
							background = false,
						},
					})
				end,
			},
			{
				"marko-cerovac/material.nvim",
				config = function()
					require("material").setup({
						contrast = {
							terminal = false,
							sidebars = false,
							floating_windows = false,
							cursor_line = false,
							lsp_virtual_text = false,
							non_current_windows = false,
						},
						styles = {
							comments = { italic = true },
							strings = {},
							keywords = { italic = true },
							functions = {},
							variables = {},
							operators = {},
							types = {},
						},
						disable = {
							colored_cursor = false,
							borders = false,
							background = true,
							term_colors = false,
							eob_lines = true,
						},
						high_visibility = {
							lighter = false,
							darker = false,
						},
						lualine_style = "stealth",
						async_loading = true,
					})
				end,
			},
			{
				"sainnhe/edge",
				config = function()
					vim.g.edge_style = "neon"
					vim.g.edge_dim_foreground = 0
					vim.g.edge_disable_italic_comment = 0
					vim.g.edge_enable_italic = 1
					vim.g.edge_cursor = "auto"
					vim.g.edge_transparent_background = 2
					vim.g.edge_dim_inactive_windows = 0
					vim.g.edge_menu_selection_background = "blue"
					vim.g.edge_spell_foreground = "none"
					vim.g.edge_show_eob = 0
					vim.g.edge_float_style = "dim"
					vim.g.edge_diagnostic_text_highlight = 0
					vim.g.edge_diagnostic_line_highlight = 0
					vim.g.edge_diagnostic_virtual_text = "grey"
					vim.g.edge_current_word = "bold"
					vim.g.edge_inlay_hints_background = "none"
					vim.g.edge_disable_terminal_colors = 0
					vim.g.edge_lightline_disable_bold = 0
					vim.g.edge_better_performance = 1
				end,
			},
			{
				"sainnhe/gruvbox-material",
				config = function()
					vim.g.gruvbox_material_style = "hard"
					vim.g.gruvbox_material_background = "hard"
					vim.g.gruvbox_material_foreground = "material"
					vim.g.gruvbox_material_disable_italic_comment = 0
					vim.g.gruvbox_material_enable_italic = 1
					vim.g.gruvbox_material_cursor = "auto"
					vim.g.gruvbox_material_transparent_background = 2
					vim.g.gruvbox_material_dim_inactive_windows = 0
					vim.g.gruvbox_material_menu_selection_background = "blue"
					vim.g.gruvbox_material_spell_foreground = "none"
					vim.g.gruvbox_material_show_eob = 0
					vim.g.gruvbox_material_float_style = "dim"
					vim.g.gruvbox_material_diagnostic_text_highlight = 0
					vim.g.gruvbox_material_diagnostic_line_highlight = 0
					vim.g.gruvbox_material_diagnostic_virtual_text = "grey"
					vim.g.gruvbox_material_current_word = "bold"
					vim.g.gruvbox_material_inlay_hints_background = "none"
					vim.g.gruvbox_material_disable_terminal_colors = 0
					vim.g.gruvbox_material_lightline_disable_bold = 0
					vim.g.gruvbox_material_better_performance = 1
				end,
			},
		},
		config = function()
			require("themery").setup({
				themes = {
					{
						name = "Catppuccin Mocha",
						colorscheme = "catppuccin",
						before = [[
							vim.g.catppuccin_flavour = "mocha"
						]],
					},
					{
						name = "Catppuccin Macchiato",
						colorscheme = "catppuccin",
						before = [[
							vim.g.catppuccin_flavour = "macchiato"
						]],
					},
					{
						name = "Catppuccin Frappe",
						colorscheme = "catppuccin",
						before = [[
							vim.g.catppuccin_flavour = "frappe"
						]],
					},
					{
						name = "Tokyonight Moon",
						colorscheme = "tokyonight",
						before = [[
							vim.g.tokyonight_style = "moon"
						]],
					},
					{
						name = "Tokyonight Storm",
						colorscheme = "tokyonight",
						before = [[
							vim.g.tokyonight_style = "storm"
						]],
					},
					{
						name = "Tokyonight Night",
						colorscheme = "tokyonight",
						before = [[
							vim.g.tokyonight_style = "night"
						]],
					},
					{
						name = "Kanagawa Wave",
						colorscheme = "kanagawa",
						before = [[
							vim.g.kanagawa_theme_style = "wave"
						]],
					},
					{
						name = "Kanagawa Dragon",
						colorscheme = "kanagawa",
						before = [[
							vim.g.kanagawa_theme_style = "dragon"
						]],
					},
					{
						name = "Onedark Deep",
						colorscheme = "onedark",
						before = [[
							vim.g.onedark_style = "deep"
						]],
					},
					{
						name = "Onedark Darker",
						colorscheme = "onedark",
						before = [[
							vim.g.onedark_style = "darker"
						]],
					},
					{
						name = "Material Deep Ocean",
						colorscheme = "material",
						before = [[
							vim.g.material_style = "deep ocean"
						]],
					},
					{
						name = "Material Oceanic",
						colorscheme = "material",
						before = [[
							vim.g.material_style = "oceanic"
						]],
					},
					{
						name = "Material Palenight",
						colorscheme = "material",
						before = [[
							vim.g.material_style = "palenight"
						]],
					},
					{
						name = "Edge Neon",
						colorscheme = "edge",
						before = [[
							vim.g.edge_style = "neon"
						]],
					},
					{
						name = "Edge Aura",
						colorscheme = "edge",
						before = [[
							vim.g.edge_style = "aura"
						]],
					},
					{
						name = "Gruvbox Material Hard",
						colorscheme = "gruvbox-material",
						before = [[
							vim.g.gruvbox_material_background = "hard"
						]],
					},
					{
						name = "Gruvbox Material Medium",
						colorscheme = "gruvbox-material",
						before = [[
							vim.g.gruvbox_material_background = "medium"
						]],
					},
					{
						name = "Nightfox",
						colorscheme = "nightfox",
					},
					{
						name = "Carbonfox",
						colorscheme = "carbonfox",
					},
					{
						name = "Duskfox",
						colorscheme = "duskfox",
					},
					{
						name = "Terafox",
						colorscheme = "terafox",
					},
				},
				livePreview = true,
				globalAfter = [[
					vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
					vim.cmd("hi NormalNC guibg=NONE ctermbg=NONE")
					vim.cmd("hi SignColumn guibg=NONE ctermbg=NONE")
					vim.cmd("hi LineNr guibg=NONE ctermbg=NONE")
					vim.cmd("hi EndOfBuffer guibg=NONE ctermbg=NONE")
					vim.cmd("hi VertSplit guibg=NONE ctermbg=NONE")
					vim.cmd("hi StatusLine guibg=NONE ctermbg=NONE")
					vim.cmd("hi StatusLineNC guibg=NONE ctermbg=NONE")
					vim.cmd("hi Pmenu guibg=NONE ctermbg=NONE")
					vim.cmd("hi FloatBorder guibg=NONE ctermbg=NONE")
					vim.cmd("hi NormalFloat guibg=NONE ctermbg=NONE")
				]],
			})

			vim.api.nvim_create_autocmd("VimEnter", {
				callback = function()
					local themery = require("themery")
					local current = themery.getCurrentTheme()

					if not current then
						themery.setThemeByName("catppuccin", true)
					end
				end,
				once = true,
			})
		end,
	},
}

return M

