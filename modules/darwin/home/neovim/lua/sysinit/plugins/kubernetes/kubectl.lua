local M = {}

M.plugins = {
	{
		"ramilito/kubectl.nvim",
		dependencies = {
			"voldikss/vim-floaterm",
		},
		config = function()
			require("kubectl").setup({
				kubectl_cmd = { cmd = "kubecolor" },
			})
		end,
		keys = function()
			return {
				{
					"<leader>kk",
					function()
						require("kubectl").toggle()
					end,
					desc = "Kubernetes: Toggle kube ui",
				},
				{
					"<leader>k9s",
					":FloatermNew! --autoclose=22 --name=k9s k9s<CR>",
					desc = "Kubernetes: Toggle k9s",
				},
			}
		end,
	},
}

return M
