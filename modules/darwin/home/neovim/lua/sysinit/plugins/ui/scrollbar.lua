local M = {}

M.plugins = {
	{
		"Xuyuanp/scrollbar.nvim",
		commit = "c96fc2fb1a3b5a9e6e82d94014490d5bca9beb9b",
		init = function()
			local group_id = vim.api.nvim_create_augroup("scrollbar_init", { clear = true })

			vim.api.nvim_create_autocmd({ "BufEnter", "WinScrolled", "WinResized" }, {
				group = group_id,
				desc = "Show or refresh scrollbar",
				pattern = { "*" },
				callback = function()
					require("scrollbar").show()
				end,
			})
		end,
	},
}

return M

