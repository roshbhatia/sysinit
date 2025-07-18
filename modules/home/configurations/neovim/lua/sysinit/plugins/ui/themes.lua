local M = {}

M.plugins = {
	{
		{
			"catppuccin/nvim",
			name = "catppuccin",
			lazy = false,
			config = function()
				require("catppuccin").setup({
					flavour = "frappe",
					show_end_of_buffer = false,
					transparent_background = true,
					term_colors = true,
					dim_inactive = {
						enabled = true,
						shade = "dark",
						percentage = 0.15,
					},
					styles = {
						comments = { "italic" },
						conditionals = { "italic" },
						loops = { "bold" },
						functions = { "bold" },
						keywords = { "italic", "bold" },
						strings = { "italic" },
						variables = {},
						numbers = { "bold" },
						booleans = { "bold", "italic" },
						properties = { "italic" },
						types = { "bold" },
						operators = { "bold" },
					},
					color_overrides = {
						frappe = {
							base = "#1e1e2e",
							mantle = "#181825",
							crust = "#11111b",
						},
					},
					highlight_overrides = {
						frappe = function(colors)
							return {
								Normal = { bg = colors.none },
								NormalNC = { bg = colors.none },
								CursorLine = { bg = colors.none },
								CursorLineNr = { fg = colors.lavender, style = { "bold" } },
								LineNr = { fg = colors.overlay0 },
								Visual = { bg = colors.surface1, style = { "bold" } },
								Search = { bg = colors.yellow, fg = colors.base, style = { "bold" } },
								IncSearch = { bg = colors.red, fg = colors.base, style = { "bold" } },
								Pmenu = { bg = colors.none, fg = colors.text },
								PmenuSel = { bg = colors.surface0, fg = colors.lavender, style = { "bold" } },
								FloatBorder = { fg = colors.lavender, bg = colors.none },
								NormalFloat = { bg = colors.none },
								TelescopeBorder = { fg = colors.lavender, bg = colors.none },
								TelescopeNormal = { bg = colors.none },
								TelescopeSelection = { bg = colors.surface0, fg = colors.lavender, style = { "bold" } },
								TelescopeTitle = { fg = colors.pink, style = { "bold" } },
								WhichKeyBorder = { fg = colors.lavender, bg = colors.none },
								WhichKeyFloat = { bg = colors.none },
								DiagnosticVirtualTextError = { bg = colors.none, fg = colors.red, style = { "italic" } },
								DiagnosticVirtualTextWarn = {
									bg = colors.none,
									fg = colors.yellow,
									style = { "italic" },
								},
								DiagnosticVirtualTextInfo = { bg = colors.none, fg = colors.blue, style = { "italic" } },
								DiagnosticVirtualTextHint = { bg = colors.none, fg = colors.teal, style = { "italic" } },
								GitSignsAdd = { fg = colors.green },
								GitSignsChange = { fg = colors.yellow },
								GitSignsDelete = { fg = colors.red },
								IndentBlanklineChar = { fg = colors.surface0 },
								IndentBlanklineContextChar = { fg = colors.surface2 },
								StatusLine = { bg = colors.none, fg = colors.text },
								StatusLineNC = { bg = colors.none, fg = colors.overlay0 },
								TabLine = { bg = colors.none, fg = colors.overlay0 },
								TabLineFill = { bg = colors.none },
								TabLineSel = { bg = colors.surface0, fg = colors.lavender, style = { "bold" } },
								WinSeparator = { fg = colors.surface0, bg = colors.none },
								SignColumn = { bg = colors.none },
								["@keyword"] = { fg = colors.mauve, style = { "italic", "bold" } },
								["@function"] = { fg = colors.blue, style = { "bold" } },
								["@string"] = { fg = colors.green, style = { "italic" } },
								["@comment"] = { fg = colors.overlay0, style = { "italic" } },
								["@variable"] = { fg = colors.text },
								["@type"] = { fg = colors.yellow, style = { "bold" } },
								["@constant"] = { fg = colors.peach, style = { "bold" } },
							}
						end,
					},
					integrations = {
						aerial = true,
						alpha = true,
						avante = true,
						cmp = true,
						dap = {
							enabled = true,
							enable_ui = true,
						},
						dap_ui = true,
						dropbar = {
							enabled = true,
							color_mode = true,
						},
						fzf = true,
						gitsigns = true,
						grug_far = true,
						hop = true,
						indent_blankline = {
							enabled = true,
							scope_color = "lavender",
							colored_indent_levels = true,
						},
						lsp_trouble = true,
						mason = true,
						native_lsp = {
							enabled = true,
							virtual_text = {
								errors = { "italic" },
								hints = { "italic" },
								warnings = { "italic" },
								information = { "italic" },
							},
							underlines = {
								errors = { "underline" },
								hints = { "underline" },
								warnings = { "underline" },
								information = { "underline" },
							},
							inlay_hints = {
								background = true,
							},
						},
						neotree = true,
						noice = true,
						notify = true,
						nvimtree = true,
						render_markdown = true,
						semantic_tokens = true,
						snacks = {
							enabled = true,
						},
						telescope = {
							enabled = true,
							style = "nvchad",
						},
						treesitter = true,
						treesitter_context = true,
						ufo = true,
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
