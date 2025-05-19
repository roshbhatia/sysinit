-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-tree/nvim-web-devicons/refs/heads/master/README.md"
local M = {}

M.plugins = {
	{
		"yaocccc/nvim-foldsign",
		event = "CursorHold",
		config = function()
			require("nvim-foldsign").setup({
				offset = -3,
				foldsigns = {
					open = "" -- mark the beginning of a fold
					close = "-", -- show a closed fold
					seps = { "│", "┃" }, -- open fold middle marker
				},
				enabled = true,
			})
		end,
	},
	{
		"nvim-tree/nvim-web-devicons",
		opts = {},
	},
}
return M

