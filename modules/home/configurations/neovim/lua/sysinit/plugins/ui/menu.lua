local M = {}

M.plugins = {
	{
		"nvzone/menu",
		dependencies = {
			"nvzone/volt",
		},
		event = "VeryLazy",
		keys = function()
			return {
				{
					mode = { "n", "v" },
					"<RightMouse>",
					function()
						require("menu.utils").delete_old_menus()

						local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
						local options = vim.bo[buf].ft == "neo-tree" or "default"

						require("menu").open(options, { mouse = true })
					end,
				},
			}
		end,
	},
}

return M
