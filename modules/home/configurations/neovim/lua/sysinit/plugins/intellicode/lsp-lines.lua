local M = {}

M.plugins = {
	{
		"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
		event = "LSPAttach",
		config = function()
			require("lsp_lines").setup()
		end,
	},
}

return M
