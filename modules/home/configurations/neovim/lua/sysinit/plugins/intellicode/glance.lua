local M = {}

M.plugins = {
	{
		"dnlhc/glance.nvim",
		cmd = "Glance",
		event = { "LspAttach" },
		opts = {

			winbar = {
				enable = true,
			},

			use_trouble_qf = true,
		},
		keys = function()
			return {
				{
					"<leader>cd",
					"<cmd>Glance definitions<cr>",
					desc = "Peek at definition",
				},
				{
					"<leader>ci",
					"<cmd>Glance implementations<cr>",
					desc = "Peek at implementations",
				},
				{
					"<leader>cu",
					"<cmd>Glance references<cr>",
					desc = "Peek at references",
				},
			}
		end,
	},
}

return M

