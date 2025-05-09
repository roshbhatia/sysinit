-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/Isrothy/neominimap.nvim/refs/heads/main/doc/neominimap.nvim.txt"
local M = {}

M.plugins = {
	{
		"Isrothy/neominimap.nvim",
		version = "v3.x.x",
		lazy = false,
		init = function()
			vim.opt_local.wrap = false
			vim.opt_local.sidescrolloff = 36

			vim.g.neominimap = {
				auto_enable = false,
			}
		end,
		keys = function()
			return {
				{
					"<leader>mm",
					"<cmd>Neominimap toggle<CR>",
					desc = "Minimap: Toggle",
				},
			}
		end,
	},
}

return M
