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
					DiagnosticError = { fg = "#ff6b6b" },
					DiagnosticWarn = { fg = "#ffa500" },
					DiagnosticInfo = { fg = "#4fc3f7" },
					DiagnosticHint = { fg = "#9c27b0" },
					DiagnosticVirtualTextError = { fg = "#ff6b6b" },
					DiagnosticVirtualTextWarn = { fg = "#ffa500" },
					DiagnosticVirtualTextInfo = { fg = "#4fc3f7" },
					DiagnosticVirtualTextHint = { fg = "#9c27b0" },
					DiagnosticUnderlineError = { undercurl = true, sp = "#ff6b6b" },
					DiagnosticUnderlineWarn = { undercurl = true, sp = "#ffa500" },
					DiagnosticUnderlineInfo = { undercurl = true, sp = "#4fc3f7" },
					DiagnosticUnderlineHint = { undercurl = true, sp = "#9c27b0" },
					DiagnosticSignError = { fg = "#ff6b6b" },
					DiagnosticSignWarn = { fg = "#ffa500" },
					DiagnosticSignInfo = { fg = "#4fc3f7" },
					DiagnosticSignHint = { fg = "#9c27b0" },

					["@lsp.type.function"] = { fg = "#4fc3f7" },
					["@lsp.type.method"] = { fg = "#4fc3f7" },
					["@lsp.type.variable"] = { fg = "text" },
					["@lsp.type.parameter"] = { fg = "subtle" },
					["@lsp.type.property"] = { fg = "rose" },
					["@lsp.type.enumMember"] = { fg = "#81c784" },
					["@lsp.type.class"] = { fg = "#ffb74d" },
					["@lsp.type.struct"] = { fg = "#ffb74d" },
					["@lsp.type.interface"] = { fg = "#ffb74d" },
					["@lsp.type.enum"] = { fg = "#ffb74d" },
					["@lsp.type.typeParameter"] = { fg = "#ba68c8" },
					["@lsp.type.keyword"] = { fg = "pine" },
					["@lsp.type.string"] = { fg = "#81c784" },
					["@lsp.type.number"] = { fg = "#f48fb1" },
					["@lsp.type.operator"] = { fg = "pine" },
					["@lsp.type.comment"] = { fg = "muted", italic = true },

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
