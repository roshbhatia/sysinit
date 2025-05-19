local M = {}

M.plugins = {
	{
		"tamton-aquib/staline.nvim",
		commit = "d337bc9b343df3c28921ef4c3f8ff604102d0201",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = {
			"BufEnter",
			"User AlphaClosed",
		},
		config = function()
			vim.opt.laststatus = 3

			local function is_lsp_active()
				local clients = vim.lsp.get_active_clients({ bufnr = 0 })
				return #clients > 0
			end

			require("staline").setup({
				sections = {
					left = { "branch", " " },
					mid = {
						"mode",
						" ",
						function()
							if is_lsp_active() then
								return " λ "
							else
								return ""
							end
						end,
					},
					right = { "filetype", " ", "line_column" },
				},
				mode_colors = {
					i = "#c6a0f6",
					n = "#8aadf4",
					c = "#a6da95",
					v = "#f5a97f",
				},
				defaults = {
					true_colors = true,
					line_column = " [%l/%L] :%c  ",
					branch_symbol = " ",
					filetype = function()
						local icon = require("nvim-web-devicons").get_icon(vim.fn.expand("%:t"))
						if icon then
							return icon .. " " .. vim.bo.filetype
						else
							return vim.bo.filetype
						end
					end,
				},
			})
		end,
	},
}

return M

