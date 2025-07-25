local M = {}

M.plugins = {
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		config = function()
			vim.opt.splitkeep = "topline"

			require("edgy").setup({
				animate = {
					enabled = false,
				},
				options = {
					left = {
						size = 40,
					},
					right = {
						size = 60,
					},
					bottom = {
						size = 0,
					},
				},
				left = {
					{
						title = " File Explorer",
						ft = "neo-tree",
						filter = function(buf)
							return vim.b[buf].neo_tree_source == "filesystem"
						end,
						size = { height = 0.5 },
						open = "Neotree position=right filesystem",
					},
					{
						title = " Open Buffers",
						ft = "neo-tree",
						filter = function(buf)
							return vim.b[buf].neo_tree_source == "buffers"
						end,
						pinned = true,
						collapsed = true,
						open = "Neotree position=top buffers",
					},
					{
						title = " Git Status",
						ft = "neo-tree",
						filter = function(buf)
							return vim.b[buf].neo_tree_source == "git_status"
						end,
						pinned = true,
						collapsed = true,
						open = "Neotree position=right git_status",
					},
				},
				right = {
					{
						title = " AI Assistant",
						ft = { "avante_input", "avante_chat" },
						filter = function(buf, win)
							local bufname = vim.api.nvim_buf_get_name(buf)
							local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
							-- Check for AI-related buffer names, types, or variables
							return bufname:match("avante")
								or bufname:match("goose")
								or buftype == "nofile"
									and (vim.b[buf].ai_assistant or vim.w[win].ai_assistant or bufname:match("Avante"))
						end,
						size = 80,
					},
				},
				icons = {
					closed = " -",
					open = " *",
				},
				wo = {
					winbar = true,
					winfixwidth = true,
					winfixheight = false,
					winhighlight = "WinBar:EdgyWinBar,Normal:EdgyNormal",
				},
			})
		end,
	},
}

return M
