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
							-- Washed out, pastel colors inspired by ThePrimeagen
							blue = "#7287c7",      -- Muted, pastel blue
							green = "#9cb380",     -- Washed out green
							yellow = "#d4c481",    -- Subtle, muted yellow
							red = "#d67b7b",       -- Soft, desaturated red
							pink = "#d19bc4",      -- Muted pink
							teal = "#7fb3aa",      -- Desaturated teal
							lavender = "#9da3d4",  -- Soft lavender
							peach = "#c7a584",     -- Muted peach
							mauve = "#b39bc7",     -- Pastel mauve
						},
					},
					highlight_overrides = {
						frappe = function(colors)
							return {
								Normal = { bg = colors.none },
								NormalNC = { bg = colors.none },
								CursorLine = { bg = colors.none },
								CursorLineNr = { fg = colors.lavender, style = { "bold" } },
								LineNr = { fg = colors.overlay1 }, -- Better contrast
								Visual = { bg = colors.surface1, style = { "bold" } },
								Search = { bg = colors.yellow, fg = colors.base, style = { "bold" } },
								IncSearch = { bg = colors.red, fg = colors.base, style = { "bold" } },
								
								-- Clean popup menus with transparency
								Pmenu = { bg = colors.none, fg = colors.text },
								PmenuSel = { bg = colors.surface0, fg = colors.lavender, style = { "bold" } },
								PmenuBorder = { fg = colors.lavender, bg = colors.none },
								
								-- Transparent floating windows
								FloatBorder = { fg = colors.lavender, bg = colors.none },
								NormalFloat = { bg = colors.none },
								FloatTitle = { fg = colors.pink, bg = colors.none, style = { "bold" } },
								
								-- Clean Telescope with transparency
								TelescopeBorder = { fg = colors.blue, bg = colors.none },
								TelescopeNormal = { bg = colors.none },
								TelescopeSelection = { bg = colors.surface0, fg = colors.lavender, style = { "bold" } },
								TelescopeTitle = { fg = colors.pink, bg = colors.none, style = { "bold" } },
								TelescopePromptBorder = { fg = colors.teal, bg = colors.none },
								TelescopePromptTitle = { fg = colors.teal, bg = colors.none, style = { "bold" } },
								TelescopeResultsBorder = { fg = colors.blue, bg = colors.none },
								TelescopeResultsTitle = { fg = colors.blue, bg = colors.none, style = { "bold" } },
								TelescopePreviewBorder = { fg = colors.green, bg = colors.none },
								TelescopePreviewTitle = { fg = colors.green, bg = colors.none, style = { "bold" } },
								
								-- Clean Which-key with transparency
								WhichKeyBorder = { fg = colors.lavender, bg = colors.none },
								WhichKeyFloat = { bg = colors.none },
								WhichKeyTitle = { fg = colors.pink, bg = colors.none, style = { "bold" } },
								WhichKey = { fg = colors.blue, style = { "bold" } },
								WhichKeyDesc = { fg = colors.text },
								WhichKeyGroup = { fg = colors.green, style = { "italic" } },
								WhichKeySeparator = { fg = colors.overlay0 },
								-- Enhanced LSP diagnostics with better visibility
								DiagnosticError = { fg = colors.red, style = { "bold" } },
								DiagnosticWarn = { fg = colors.yellow, style = { "bold" } },
								DiagnosticInfo = { fg = colors.blue, style = { "bold" } },
								DiagnosticHint = { fg = colors.teal, style = { "bold" } },
								DiagnosticVirtualTextError = { bg = colors.none, fg = colors.red, style = { "italic" } },
								DiagnosticVirtualTextWarn = { bg = colors.none, fg = colors.yellow, style = { "italic" } },
								DiagnosticVirtualTextInfo = { bg = colors.none, fg = colors.blue, style = { "italic" } },
								DiagnosticVirtualTextHint = { bg = colors.none, fg = colors.teal, style = { "italic" } },
								DiagnosticUnderlineError = { undercurl = true, sp = colors.red },
								DiagnosticUnderlineWarn = { undercurl = true, sp = colors.yellow },
								DiagnosticUnderlineInfo = { undercurl = true, sp = colors.blue },
								DiagnosticUnderlineHint = { undercurl = true, sp = colors.teal },
								
								-- Enhanced Git signs with better contrast
								GitSignsAdd = { fg = colors.green, style = { "bold" } },
								GitSignsChange = { fg = colors.yellow, style = { "bold" } },
								GitSignsDelete = { fg = colors.red, style = { "bold" } },
								GitSignsAddInline = { bg = colors.green, fg = colors.base },
								GitSignsChangeInline = { bg = colors.yellow, fg = colors.base },
								GitSignsDeleteInline = { bg = colors.red, fg = colors.base },
								-- Enhanced indentation guides
								IndentBlanklineChar = { fg = colors.surface0 },
								IndentBlanklineContextChar = { fg = colors.lavender, style = { "bold" } },
								IndentBlanklineContextStart = { sp = colors.lavender, underline = true },
								
								-- Modern status line and tabs
								StatusLine = { bg = colors.none, fg = colors.text },
								StatusLineNC = { bg = colors.none, fg = colors.overlay1 },
								TabLine = { bg = colors.none, fg = colors.overlay1 },
								TabLineFill = { bg = colors.none },
								TabLineSel = { bg = colors.blue, fg = colors.base, style = { "bold" } },
								
								-- Enhanced window separators and columns
								WinSeparator = { fg = colors.blue, bg = colors.none, style = { "bold" } },
								SignColumn = { bg = colors.none },
								ColorColumn = { bg = colors.surface0 },
								
								-- Enhanced syntax highlighting with better contrast
								["@keyword"] = { fg = colors.mauve, style = { "italic", "bold" } },
								["@keyword.function"] = { fg = colors.pink, style = { "italic", "bold" } },
								["@keyword.operator"] = { fg = colors.mauve, style = { "bold" } },
								["@function"] = { fg = colors.blue, style = { "bold" } },
								["@function.call"] = { fg = colors.blue },
								["@method"] = { fg = colors.blue, style = { "bold" } },
								["@string"] = { fg = colors.green, style = { "italic" } },
								["@string.escape"] = { fg = colors.pink, style = { "bold" } },
								["@comment"] = { fg = colors.overlay1, style = { "italic" } },
								["@variable"] = { fg = colors.text },
								["@variable.builtin"] = { fg = colors.red, style = { "italic" } },
								["@type"] = { fg = colors.yellow, style = { "bold" } },
								["@type.builtin"] = { fg = colors.yellow, style = { "italic", "bold" } },
								["@constant"] = { fg = colors.peach, style = { "bold" } },
								["@constant.builtin"] = { fg = colors.peach, style = { "italic", "bold" } },
								["@number"] = { fg = colors.peach, style = { "bold" } },
								["@boolean"] = { fg = colors.peach, style = { "italic", "bold" } },
								["@operator"] = { fg = colors.teal, style = { "bold" } },
								["@punctuation"] = { fg = colors.overlay2 },
								["@punctuation.bracket"] = { fg = colors.overlay2, style = { "bold" } },
								["@tag"] = { fg = colors.red, style = { "bold" } },
								["@tag.attribute"] = { fg = colors.yellow, style = { "italic" } },
								["@property"] = { fg = colors.lavender, style = { "italic" } },
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
