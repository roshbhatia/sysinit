local M = {}

M.plugins = {
	{
		"Piotr1215/telescope-crossplane.nvim",
		requires = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("telescope").load_extension("telescope-crossplane")
		end,
		keys = function()
			return {
				{
					"<leader>kmr",
					":Telescope telescope-crossplane crossplane_managed_resources<cr>",
					desc = "Kubernetes: Crossplane Managed Resources",
				},
				{
					"<leader>kxr",
					":Telescope telescope-crossplane crossplane_resources<cr>",
					desc = "Kubernetes: Crossplane Resources",
				},
			}
		end,
	},
}

return M
