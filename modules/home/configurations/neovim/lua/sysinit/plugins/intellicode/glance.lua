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
					desc = "Peek definition",
				},
				{
					"<leader>ci",
					"<cmd>Glance implementations<cr>",
					desc = "Peek implementations",
				},
				{
					"<leader>cu",
					"<cmd>Glance references<cr>",
					desc = "Peek references",
				},
			}
		end,
	},
}

return M
