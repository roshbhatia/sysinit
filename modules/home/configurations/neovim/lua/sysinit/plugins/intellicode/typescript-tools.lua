local M = {}

M.plugins = {
	{
		"pmizio/typescript-tools.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			complete_function_calls = true,
			expose_as_code_action = "all",
			code_lens = "all",
		},
		event = {
			"BufReadPost",
		},
		ft = {
			"ts",
			"js",
			"json",
		},
	},
}

return M

