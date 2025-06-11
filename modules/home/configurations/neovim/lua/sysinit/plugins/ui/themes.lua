local M = {}
M.plugins = {
	{
		"rose-pine/neovim",
		name = "rose-pine",
		config = function()
			require("rose-pine").setup({
				variant = "main",
				styles = {
					transparency = true,
				},
				palette = {
					main = {
						base = "#191724",
						surface = "#1f1d2e",
						overlay = "#26233a",
						muted = "#6e6a86",
						subtle = "#908caa",
						text = "#e0def4",

						love = "#c5838a",
						gold = "#d4b896",
						rose = "#d4a8a5",
						pine = "#5a8394",
						foam = "#7db5bd",
						iris = "#a494c2",
						leaf = "#7a9690",

						highlight_low = "#21202e",
						highlight_med = "#403d52",
						highlight_high = "#524f67",
					},
				},
				highlight_groups = {
					DiagnosticError = { fg = "#eb6f92" },
					DiagnosticWarn = { fg = "#f6c177" },
					DiagnosticInfo = { fg = "#31748f" },
					DiagnosticHint = { fg = "#c4a7e7" },
					DiagnosticVirtualTextError = { fg = "#eb6f92" },
					DiagnosticVirtualTextWarn = { fg = "#f6c177" },
					DiagnosticVirtualTextInfo = { fg = "#31748f" },
					DiagnosticVirtualTextHint = { fg = "#c4a7e7" },
					DiagnosticUnderlineError = { undercurl = true, sp = "#eb6f92" },
					DiagnosticUnderlineWarn = { undercurl = true, sp = "#f6c177" },
					DiagnosticUnderlineInfo = { undercurl = true, sp = "#31748f" },
					DiagnosticUnderlineHint = { undercurl = true, sp = "#c4a7e7" },
					DiagnosticSignError = { fg = "#eb6f92" },
					DiagnosticSignWarn = { fg = "#f6c177" },
					DiagnosticSignInfo = { fg = "#31748f" },
					DiagnosticSignHint = { fg = "#c4a7e7" },

					["@lsp.type.function"] = { fg = "#9ccfd8" },
					["@lsp.type.method"] = { fg = "#9ccfd8" },
					["@lsp.type.variable"] = { fg = "text" },
					["@lsp.type.parameter"] = { fg = "subtle" },
					["@lsp.type.property"] = { fg = "rose" },
					["@lsp.type.enumMember"] = { fg = "#31748f" },
					["@lsp.type.class"] = { fg = "#f6c177" },
					["@lsp.type.struct"] = { fg = "#f6c177" },
					["@lsp.type.interface"] = { fg = "#f6c177" },
					["@lsp.type.enum"] = { fg = "#f6c177" },
					["@lsp.type.typeParameter"] = { fg = "#c4a7e7" },
					["@lsp.type.keyword"] = { fg = "pine" },
					["@lsp.type.string"] = { fg = "#95b1ac" },
					["@lsp.type.number"] = { fg = "#ebbcba" },
					["@lsp.type.operator"] = { fg = "pine" },
					["@lsp.type.comment"] = { fg = "muted", italic = true },

					SnacksNotifierError = { fg = "#eb6f92", bg = "surface" },
					SnacksNotifierWarn = { fg = "#f6c177", bg = "surface" },
					SnacksNotifierInfo = { fg = "#31748f", bg = "surface" },
					SnacksNotifierDebug = { fg = "#c4a7e7", bg = "surface" },
					SnacksNotifierTrace = { fg = "subtle", bg = "surface" },
					SnacksNotifierIconError = { fg = "#eb6f92" },
					SnacksNotifierIconWarn = { fg = "#f6c177" },
					SnacksNotifierIconInfo = { fg = "#31748f" },
					SnacksNotifierIconDebug = { fg = "#c4a7e7" },
					SnacksNotifierIconTrace = { fg = "subtle" },
					SnacksNotifierTitleError = { fg = "#eb6f92" },
					SnacksNotifierTitleWarn = { fg = "#f6c177" },
					SnacksNotifierTitleInfo = { fg = "#31748f" },
					SnacksNotifierTitleDebug = { fg = "#c4a7e7" },
					SnacksNotifierTitleTrace = { fg = "subtle" },
					SnacksNotifierBorderError = { fg = "#eb6f92" },
					SnacksNotifierBorderWarn = { fg = "#f6c177" },
					SnacksNotifierBorderInfo = { fg = "#31748f" },
					SnacksNotifierBorderDebug = { fg = "#c4a7e7" },
					SnacksNotifierBorderTrace = { fg = "subtle" },

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
			vim.cmd("colorscheme rose-pine")
		end,
	},
}
return M
