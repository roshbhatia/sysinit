local M = {}

M.plugins = {
	{
		"aznhe21/actions-preview.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
		},
		event = "LSPAttach",
		config = function()
			require("actions-preview").setup({
				telescope = vim.tbl_extend("force", require("telescope.themes").get_ivy(), {
					make_value = nil,
					make_make_display = nil,
				}),
			})
		end,
		keys = function()
			return {
				{
					"<leader>ca",
					function()
						require("actions-preview").code_actions()
					end,
					desc = "Code action",
				},
				{
					"<leader>ca",
					function()
						require("actions-preview").code_actions()
					end,
					mode = "v",
					desc = "Code action",
				},
			}
		end,
	},
}

return M
