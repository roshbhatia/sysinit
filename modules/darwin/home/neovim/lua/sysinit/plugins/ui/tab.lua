local M = {}

M.plugins = {
	{
		"nanozuki/tabby.nvim",
		event = "User AlphaClosed",
		dependencies = { "nvim-tree/nvim-web-devicons", "xiyaowong/transparent.nvim" },
		config = function()
			vim.opt.showtabline = 2

			require("tabby").setup({
				preset = "tab_only",
				option = {
					theme = {
						fill = "TabLineFill", -- tabline background
						head = "TabLine", -- head element highlight
						current_tab = "TabLineSel", -- current tab label highlight
						tab = "TabLine", -- other tab label highlight
						win = "TabLine", -- window highlight
						tail = "TabLine", -- tail element highlight
					},
					nerdfont = true, -- whether use nerdfont
					lualine_theme = nil, -- lualine theme name
					tab_name = {
						name_fallback = function(tabid)
							return tabid
						end,
					},
					buf_name = {
						mode = "unique", -- or 'relative', 'tail', 'shorten'
					},
				},
			})

			require("transparent").clear_prefix("TabLine")
		end,
		keys = function()
			-- Uses default tabnew, tab close, tab next, tab prev, tab move, and the command Tabby jump_to_tab
			return {
				{
					"<leader>tj",
					"<cmd>Tabby jump_to_tab<CR>",
					mode = "n",
					desc = "Tab: Jump to tab",
				},
				{
					"<leader>ti",
					":$tabnew<CR>",
					mode = "n",
					desc = "Tab: New tab",
				},
				{
					"<leader>tc",
					":tabclose<CR>",
					mode = "n",
					desc = "Tab: Close tab",
				},
				{
					"<leader>tn",
					":tabn<CR>",
					mode = "n",
					desc = "Tab: Next tab",
				},
				{
					"<leader>tp",
					":tabp<CR>",
					mode = "n",
					desc = "Tab: Previous tab",
				},
				{
					"<leader>tm-",
					":-tabmove<CR>",
					mode = "n",
					desc = "Tab: Move tab to previous position",
				},
				{
					"<leader>tm+",
					":+tabmove<CR>",
					mode = "n",
					desc = "Tab: Move tab to next position",
				},
			}
		end,
	},
}

return M
