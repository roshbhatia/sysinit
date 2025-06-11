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
						love = "#eb6f92",
						gold = "#f6c177",
						rose = "#ebbcba",
						pine = "#3e445e",
						foam = "#a3a9c5",
						iris = "#c4a7e7",
						leaf = "#a9b665",
						highlight_low = "#21202e",
						highlight_med = "#2a283b",
						highlight_high = "#2f2d44",
					},
				},
				highlight_groups = {
					DiagnosticError = { fg = "#eb6f92" },
					DiagnosticWarn = { fg = "#f6c177" },
					DiagnosticInfo = { fg = "#a9b665" },
					DiagnosticHint = { fg = "#c4a7e7" },
					DiagnosticVirtualTextError = { fg = "#eb6f92" },
					DiagnosticVirtualTextWarn = { fg = "#f6c177" },
					DiagnosticVirtualTextInfo = { fg = "#a9b665" },
					DiagnosticVirtualTextHint = { fg = "#c4a7e7" },
					DiagnosticUnderlineError = { undercurl = true, sp = "#eb6f92" },
					DiagnosticUnderlineWarn = { undercurl = true, sp = "#f6c177" },
					DiagnosticUnderlineInfo = { undercurl = true, sp = "#a9b665" },
					DiagnosticUnderlineHint = { undercurl = true, sp = "#c4a7e7" },
					DiagnosticSignError = { fg = "#eb6f92" },
					DiagnosticSignWarn = { fg = "#f6c177" },
					DiagnosticSignInfo = { fg = "#a9b665" },
					DiagnosticSignHint = { fg = "#c4a7e7" },

					["@lsp.type.function"] = { fg = "#f6c177" },
					["@lsp.type.method"] = { fg = "#f6c177" },
					["@lsp.type.variable"] = { fg = "text" },
					["@lsp.type.parameter"] = { fg = "subtle" },
					["@lsp.type.property"] = { fg = "leaf" },
					["@lsp.type.enumMember"] = { fg = "#ddb6c8" },
					["@lsp.type.class"] = { fg = "#a9b665" },
					["@lsp.type.struct"] = { fg = "#a9b665" },
					["@lsp.type.interface"] = { fg = "#a9b665" },
					["@lsp.type.enum"] = { fg = "#a9b665" },
					["@lsp.type.typeParameter"] = { fg = "#a3a9c5" },
					["@lsp.type.keyword"] = { fg = "pine" },
					["@lsp.type.string"] = { fg = "#c0c58c" },
					["@lsp.type.number"] = { fg = "#e0bfc0" },
					["@lsp.type.operator"] = { fg = "leaf" },
					["@lsp.type.comment"] = { fg = "muted", italic = true },

					SnacksNotifierError = { fg = "#eb6f92", bg = "surface" },
					SnacksNotifierWarn = { fg = "#f6c177", bg = "surface" },
					SnacksNotifierInfo = { fg = "#a9b665", bg = "surface" },
					SnacksNotifierDebug = { fg = "#c4a7e7", bg = "surface" },
					SnacksNotifierTrace = { fg = "subtle", bg = "surface" },
					SnacksNotifierIconError = { fg = "#eb6f92" },
					SnacksNotifierIconWarn = { fg = "#f6c177" },
					SnacksNotifierIconInfo = { fg = "#a9b665" },
					SnacksNotifierIconDebug = { fg = "#c4a7e7" },
					SnacksNotifierIconTrace = { fg = "subtle" },
					SnacksNotifierTitleError = { fg = "#eb6f92" },
					SnacksNotifierTitleWarn = { fg = "#f6c177" },
					SnacksNotifierTitleInfo = { fg = "#a9b665" },
					SnacksNotifierTitleDebug = { fg = "#c4a7e7" },
					SnacksNotifierTitleTrace = { fg = "subtle" },
					SnacksNotifierBorderError = { fg = "#eb6f92" },
					SnacksNotifierBorderWarn = { fg = "#f6c177" },
					SnacksNotifierBorderInfo = { fg = "#a9b665" },
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
						fg = "#2c2a3e",
						bg = "#26233a",
					},
					TelescopeNormal = {
						fg = "text",
						bg = "#26233a",
					},
					TelescopeSelection = {
						fg = "text",
						bg = "#2f2d44",
					},
					TelescopeSelectionCaret = {
						fg = "gold",
						bg = "#2f2d44",
					},
					TelescopeMultiSelection = {
						fg = "text",
						bg = "#3a3850",
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
						bg = "leaf",
					},
					TelescopePromptNormal = {
						fg = "text",
						bg = "#201f2f",
					},
					TelescopePromptBorder = {
						fg = "#201f2f",
						bg = "#201f2f",
					},

					WinBar = { fg = "text", bg = "NONE" },
					WinBarNC = { fg = "subtle", bg = "NONE" },
					DropBarCurrentContext = { fg = "text", bg = "NONE" },
					DropBarHover = { fg = "text", bg = "highlight_low" },
					DropBarIconKindDefault = { fg = "subtle", bg = "NONE" },
					DropBarMenuNormalFloat = { fg = "text", bg = "overlay" },
					DropBarMenuFloatBorder = { fg = "muted", bg = "overlay" },
					DropBarMenuCurrentContext = { fg = "text", bg = "highlight_med" },
					DropBarMenuHoverEntry = { fg = "text", bg = "highlight_high" },
				},
			})
			vim.cmd("colorscheme rose-pine")
		end,
	},
}

return M
