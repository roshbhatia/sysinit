local M = {}

M.plugins = {
	{
		"olimorris/persisted.nvim",
		lazy = false,
		config = function()
			vim.o.sessionoptions = "buffers,curdir,folds,globals,tabpages,winpos,winsize"

			require("persisted").setup({
				save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/.." .. "/sessions/"),
				autoload = true,
				on_autoload_no_session = function()
					vim.cmd("Alpha")
				end,
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "PersistedLoadPost",
				callback = function()
					vim.defer_fn(function()
						vim.cmd("bufdo e!")
						vim.cmd("Neotree show")
					end, 50)
				end,
			})
		end,
	},
}

return M

