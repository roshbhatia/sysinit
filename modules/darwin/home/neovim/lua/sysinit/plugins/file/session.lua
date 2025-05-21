local M = {}

M.plugins = {
	{
		"olimorris/persisted.nvim",
		lazy = false,
		config = function()
			require("persisted").setup({
				use_git_branch = true,
				autoload = true,
				on_autoload_no_session = function()
					vim.cmd("Alpha")
				end,
				should_save = function()
					-- Do not save if the alpha dashboard is the current filetype
					if vim.bo.filetype == "alpha" then
						return false
					end
					return true
				end,
			})
		end,
	},
}

return M

