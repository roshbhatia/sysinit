local M = {}

M.plugins = {
	{
		"iyaowong/transparent.nvim",
		lazy = false,
		configure = function()
			require("transparent").setup()

			vim.api.nvim_create_autocmd("VimEnter", {
				pattern = "*",
				callback = function()
					vim.cmd("TransparentEnable")
				end,
			})
		end,
	},
}

return M
