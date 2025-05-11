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
					":FloatermNew! --autoclose=2 --width=0.8 --height=0.8 --name=k9s k9s<CR>",
					desc = "Kubernetes: Toggle k9s",
				},
			}
		end,
	},
}

return M
