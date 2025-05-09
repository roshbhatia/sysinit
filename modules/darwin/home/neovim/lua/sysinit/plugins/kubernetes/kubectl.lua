local M = {}

M.plugins = {
	{
		"ramilito/kubectl.nvim",
		config = function()
			require("kubectl").setup({
				kubectl_cmd = { cmd = "kubecolor" },
			})
		end,
	},
	keys = function()
		return {
			{
				"<leader>kk",
				function()
					require("kubectl").toggle()
				end,
				desc = "Kubernetes: Toggle kubectl",
			},
		}
	end,
}

return M
