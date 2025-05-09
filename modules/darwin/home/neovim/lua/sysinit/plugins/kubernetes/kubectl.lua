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
					desc = "Kubernetes: Toggle kubectl",
				},
				{
					"<leader>k9s",
					'<cmd>FloatermNew --name=k9s --cmd="k9s"<CR>',
					desc = "Kubernetes: Toggle k9s",
				},
			}
		end,
	},
}

return M
