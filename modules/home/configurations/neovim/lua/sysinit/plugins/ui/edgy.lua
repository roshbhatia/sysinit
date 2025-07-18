local M = {}

M.plugins = {
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		config = function()
			vim.opt.splitkeep = "topline"

			require("edgy").setup({
				animate = {
					enabled = true,
					fps = 144,
					cps = 360,
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
					},
				},
				right = {
					{
						title = " AI Assistant",
						ft = { "avante_input", "avante_chat", "codecompanion", "opencode_input", "opencode_output" },
						filter = function(buf, win)
							local bufname = vim.api.nvim_buf_get_name(buf)
							local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
							-- Check for AI-related buffer names, types, or variables
							return bufname:match("avante")
								or bufname:match("codecompanion")
								or bufname:match("goose")
								or bufname:match("opencode")
								or buftype == "nofile"
									and (vim.b[buf].ai_assistant or vim.w[win].ai_assistant or bufname:match("Avante") or bufname:match(
										"CodeCompanion"
									) or bufname:match("Goose") or bufname:match("Opencode"))
						end,
						size = 80,
					},
				},
				bottom = {
					{
						title = " Terminal",
						ft = "toggleterm",
						size = 0.3,
					},
				},
				icons = {
					closed = "󰅂",
					open = "󰅀",
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
