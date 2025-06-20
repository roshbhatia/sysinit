local M = {}

M.plugins = {
	{
		"tamton-aquib/staline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = {
			"BufEnter",
			"User AlphaClosed",
		},
		config = function()
			require("staline").setup({
				sections = {
					left = {
						"mode",
						"branch",
						" ",
						"lsp",
					},
					mid = {
						function()
							local ok, git_blame = pcall(require, "gitblame")
							if not ok then
								return ""
							end

							if git_blame.is_blame_text_available and git_blame.is_blame_text_available() then
								return git_blame.get_current_blame_text()
							else
								return ""
							end
						end,
					},
					right = {
						"line_column",
						"cool_symbol",
					},
				},
				mode_icons = {
					c = "󰸸 ",
					i = "󰸴 ",
					n = "󰸶 ",
					t = "󰸷 ",
					v = "󰸵 ",
				},
				lsp_symbols = {
					Error = " ",
					Hint = " ",
					Info = " ",
					Warn = " ",
				},
				defaults = {
					cool_symbol = "󱄅",
					expand_null_ls = false,
					true_colors = true,
					line_column = ":%c [%l/%L]",
					lsp_client_symbol = "",
					lsp_client_character_length = 40,
				},
			})
		end,
	},
}

return M

