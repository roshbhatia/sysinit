-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-tree/nvim-web-devicons/refs/heads/master/README.md"
local M = {}

M.plugins = {
	{ "yaocccc/nvim-foldsign", event = "CursorHold", config = 'require("nvim-foldsign").setup()' },
	{
		"nvim-tree/nvim-web-devicons",
		opts = {},
	},
}
return M

