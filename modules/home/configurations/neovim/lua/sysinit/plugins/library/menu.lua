local M = {}

M.plugins = {
	{
		"nvzone/menu",
		lazy = true,
		dependencies = {
			"nvzone/volt",
		},
		keys = function()
			return {
				{
					"<RightMouse>",
					function()
						require("menu.utils").delete_old_menus()
						vim.cmd("normal! <RightMouse>")
						local mousepos = vim.fn.getmousepos()
						local buf = vim.api.nvim_win_get_buf(mousepos.winid)
						---@diagnostic disable-next-line: deprecated
						local ft = vim.api.nvim_buf_get_option(buf, "filetype")
						if ft == "neo-tree" then
							require("menu").open("neo-tree", { mouse = true })
						else
							require("menu").open("default", { mouse = true })
						end
					end,
					desc = "Open menu with mouse",
				},
			}
		end,
	},
}

return M

