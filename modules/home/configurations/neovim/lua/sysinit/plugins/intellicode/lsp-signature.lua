local M = {}

M.plugins = {
	{
		"ray-x/lsp_signature.nvim",
		event = "LSPAttach",
		config = function()
			require("lsp_signature").setup({})
		end,
	},
}

return M
