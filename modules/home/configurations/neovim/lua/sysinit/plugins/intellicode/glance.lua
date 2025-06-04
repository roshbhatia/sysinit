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
					"Glance definitions",
					desc = "Peek definition",
				},
				{
					"<leader>ci",
					"Glance implementations",
					desc = "Peek implementations",
				},
				{
					"<leader>cu",
					"Glance references",
					desc = "Peek references",
				},
			}
		end,
	},
}

return M
