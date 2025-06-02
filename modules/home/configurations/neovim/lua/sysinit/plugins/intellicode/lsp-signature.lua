local M = {}

M.plugins = {
	{
		"ray-x/lsp_signature.nvim",
		event = "LSPAttach",
		opts = {},
	},
}

return M
