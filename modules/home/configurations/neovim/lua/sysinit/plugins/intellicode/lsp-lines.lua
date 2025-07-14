local M = {}

M.plugins = {
	{
		"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
		event = "LSPAttach",
		config = function()
			require("lsp_lines").setup()
		end,
		keys = function()
			return {
				{
					"<localleader>cc",
					require("lsp_lines").toggle,
					mode = "n",
					noremap = true,
					silent = true,
					{
						desc = "Toggle LSP Diagnostics",
					},
				},
			}
		end,
	},
}

return M

