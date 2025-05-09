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
					"<leader>kg",
					"<cmd>FloatermToggle -wintype=float --name=k9s --position=center --autoclose=2 k9s<CR>",
					desc = "Kubernetes: Toggle k9s",
				},
			}
		end,
	},
}

return M

